// @ts-check
import express = require('express');
import fileUpload = require('express-fileupload');
import morgan = require('morgan');
import { Pool } from 'pg';
import axios from 'axios';
import { Provider } from '@reef-defi/evm-provider';
import { WsProvider } from '@polkadot/api';
import crypto = require('crypto');
import { default as fetch } from 'node-fetch';
import { ethers } from 'ethers';
import config = require('../api.config');
import { UploadedFile } from 'express-fileupload';

//
// Interfaces
//

interface Token {
  name: string;
  address: string;
  iconUrl: string;
  userBalance: string;
  decimals: number;
}

interface BasicPool {
  decimals: number
  reserve1: string;
  reserve2: string;
  totalSupply: string;
  poolAddress: string;
  minimumLiquidity: string;
  userPoolBalance: string;
}

// Renamed from Pool to ReefPool to avoid name collision with pg Pool
interface ReefPool extends BasicPool {
  token1: Token;
  token2: Token;
}

// User address can be empty! 
// When it is return default values with user info set to 0 (userBalance, userPoolBalance, ...)
interface BasicReq {
  userAddress?: string;
}

interface TokenReq extends BasicReq {
  tokenAddress: string;
}

interface PoolReq extends BasicReq {
  tokenAddress1: string;
  tokenAddress2: string;
}


//
// Functions
//

const ensure = (condition: boolean, message: string) => {
  if (!condition) {
    throw new Error(message);
  }
}

// Connnect to db
// TODO: refactor!!!
const getPool = async (): Promise<Pool> => {
  const pool = new Pool(config.postgresConnParams);
  await pool.connect();
  return pool;
}

// Parametrized database query
const parametrizedDbQuery = async (pool: any, query: string, data: any[]): Promise<any> | null => {
  try {
    return await pool.query(query, data);
  } catch (error) {
    return null;
  }
};

// Remove metadata from bytecode
const preprocessBytecode = (bytecode: string): string => {
  let filteredBytecode = "";
  const start = bytecode.indexOf('6080604052');
  //
  // metadata separator (solc >= v0.6.0)
  //
  const ipfsMetadataEnd = bytecode.indexOf('a264697066735822');
  filteredBytecode = bytecode.slice(start, ipfsMetadataEnd);

  //
  // metadata separator for 0.5.16
  //
  const bzzr1MetadataEnd = filteredBytecode.indexOf('a265627a7a72315820');
  filteredBytecode = filteredBytecode.slice(0, bzzr1MetadataEnd);

  return filteredBytecode;
};

// Get not verified contracts with 100% matching bytecde (excluding metadata)
const getOnChainContractsByBytecode = async(pool: any, bytecode: string): Promise<string[]> => {
  const query = `SELECT contract_id FROM contract WHERE bytecode LIKE $1 AND NOT verified;`;
  const preprocessedBytecode = preprocessBytecode(bytecode);
  const data = [`0x${preprocessedBytecode}%`];
  const res = await parametrizedDbQuery(pool, query, data);
  if (res) {
    if (res.rows.length > 0) {
      return res.rows.map(({ contract_id }) => contract_id);
    }
  }
  return []
};


//
// Express setup
//
const app = express();

// Parse incoming requests with JSON payloads
app.use(express.urlencoded({extended: true}));
app.use(express.json());

// Logger
app.use(morgan('dev'));

// Enable file upload
app.use(fileUpload({
  createParentPath: true,
  limits: { 
    fileSize: 1 * 1024 * 1024 * 1024 // 1MB max file(s) size
  },
}));

// Make uploads directory static
app.use(express.static('uploads'));

//
// Old endpoints, TODO: convert to ts!
//
app.post('/api/verificator/request', async (req: any, res) => {
  try {
    if(!req.files || !req.body.token || !req.body.address || !req.body.compilerVersion || !req.body.optimization || !req.body.optimization || !req.body.runs || !req.body.target || !req.body.license) {
      res.send({
        status: false,
        message: 'Input error'
      });
    } else {
      // console.log(req);
      const token = req.body.token;
      const response = await fetch(
        `https://www.google.com/recaptcha/api/siteverify?secret=${config.recaptchaSecret}&response=${token}`
      );
      const success = JSON.parse(await response.text()).success;
      if (success) {     
        const source = req.files.source as UploadedFile;

        // check file extension, only .sol is allowed
        const fileName = source.name;
        const fileExtension = fileName.split('.').pop();
        if (fileExtension !== 'sol') {
          res.send({
            status: false,
            message: 'File error: only sol extension is allowed'
          });
        }

        // Insert contract_verification_request
        const sourceFileContent = source.data.toString('utf8');
        const id = crypto.randomBytes(20).toString('hex');
        const timestamp = Date.now();
        const pool = await getPool();
        const sql = `INSERT INTO contract_verification_request (
          id,
          contract_id,
          source,
          filename,
          compiler_version,
          optimization,
          runs,
          target,
          license,
          status,
          timestamp
        ) VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7,
          $8,
          $9,
          $10,
          $11
        );`;
        const data = [
          id,
          req.body.address,
          sourceFileContent.replace(/\x00/g,''),
          fileName,
          req.body.compilerVersion,
          req.body.optimization,
          req.body.runs,
          req.body.target,
          req.body.license,
          'PENDING',
          timestamp
        ];
        try {
          await pool.query(sql, data);
          res.send({
            status: true,
            message: 'Received verification request',
            data: {
              id,
              address: req.body.address,
              source: fileName,
              sourceMimetype: source.mimetype,
              sourceSize: source.size,
              compilerVersion: req.body.compilerVersion,
              optimization: req.body.optimization,
              runs: req.body.runs,
              target: req.body.target,
              license: req.body.license,
            }
          });
        } catch (error) {
          console.log('Database error:', error);
          res.send({
            status: false,
            message: 'Database error'
          });
        }
        await pool.end();
      } else {
        res.send({
          status: false,
          message: 'Token error'
        });
      }
    }
  } catch (err) {
    res.status(500).send(err);
  }
});

//
// Endpoint: /api/verificator/deployed-bytecode-request
//
// Method: POST
//
// Params:
//
// address: contract address
// name: contract name (of the main contract)
// source: source code
// bytecode: deployed bytecode
// arguments: contract arguments (stringified json)
// abi: contract abi (stringified json)
// compilerVersion: i.e: v0.8.6+commit.11564f7e
// optimization: true | false
// runs: optimization runs
// target: default | homestead | tangerineWhistle | spuriousDragon | byzantium | constantinople | petersburg | istanbul
// license: "unlicense" | "MIT" | "GNU GPLv2" | "GNU GPLv3" | "GNU LGPLv2.1" | "GNU LGPLv3" | "BSD-2-Clause" | "BSD-3-Clause" | "MPL-2.0" | "OSL-3.0" | "Apache-2.0" | "GNU AGPLv3"
//

app.post('/api/verificator/deployed-bytecode-request', async (req: any, res) => {
  try {
    if(
      !req.body.address
      || !req.body.name
      || !req.body.source
      || !req.body.bytecode
      || !req.body.arguments
      || !req.body.abi
      || !req.body.compilerVersion
      || !req.body.optimization
      || !req.body.runs
      || !req.body.target
      || !req.body.license
    ) {
      res.send({
        status: false,
        message: 'Input error'
      });
    } else {
      let {
        address,
        name,
        source,
        bytecode,
        arguments:args,
        abi,
        compilerVersion,
        optimization,
        runs,
        target,
        license,
      } = req.body;
      const pool = await getPool();
      const query = "SELECT contract_id, verified, bytecode FROM contract WHERE contract_id = $1 AND bytecode LIKE $2;";
      const preprocessedRequestContractBytecode = preprocessBytecode(bytecode);
      const data = [address, `0x${preprocessedRequestContractBytecode}%`];
      const dbres = await pool.query(query, data);
      if (dbres) {
        if (dbres.rows.length === 1) {
          const onChainContractBytecode = dbres.rows[0].bytecode;
          const preprocessedOnChainContractBytecode = preprocessBytecode(onChainContractBytecode);
          if (dbres.rows[0].verified === true && preprocessedOnChainContractBytecode === preprocessedRequestContractBytecode) {
            res.send({
              status: false,
              message: 'Error, contract already verified'
            });
          } else {
            // connect to provider
            const provider = new Provider({
              provider: new WsProvider(config.nodeWs),
            });
            await provider.api.isReady

            const isVerified = true;
            // find out default target
            if (target === 'default') {
              // v0.4.12
              const compilerVersionNumber = compilerVersion
                .split('-')[0]
                .split('+')[0]
                .substring(1)
              const compilerVersionNumber1 = parseInt(
                compilerVersionNumber.split('.')[0]
              )
              const compilerVersionNumber2 = parseInt(
                compilerVersionNumber.split('.')[1]
              )
              const compilerVersionNumber3 = parseInt(
                compilerVersionNumber.split('.')[2]
              )
              if (
                compilerVersionNumber1 === 0 &&
                compilerVersionNumber2 <= 5 &&
                compilerVersionNumber3 <= 4
              ) {
                target = 'byzantium'
              } else if (
                compilerVersionNumber1 === 0 &&
                compilerVersionNumber2 >= 5 &&
                compilerVersionNumber3 >= 5 &&
                compilerVersionNumber3 < 14
              ) {
                target = 'petersburg'
              } else {
                target = 'istanbul'
              }
            }
            // verify all not verified contracts with the same bytecode
            const matchedContracts = await getOnChainContractsByBytecode(pool, onChainContractBytecode);
            for (const matchedContractId of matchedContracts) {
              //
              // check standard ERC20 interface: https://ethereum.org/en/developers/docs/standards/tokens/erc-20/ 
              //
              // function name() public view returns (string)
              // function symbol() public view returns (string)
              // function decimals() public view returns (uint8)
              // function totalSupply() public view returns (uint256)
              // function balanceOf(address _owner) public view returns (uint256 balance)
              // function transfer(address _to, uint256 _value) public returns (bool success)
              // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
              // function approve(address _spender, uint256 _value) public returns (bool success)
              // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
              //
              let isErc20 = false;
              let tokenName = null;
              let tokenSymbol = null;
              let tokenDecimals = null;
              let tokenTotalSupply = null;
              const contract = new ethers.Contract(
                matchedContractId,
                abi,
                provider
              )

              if (
                typeof contract['name'] === 'function'
                && typeof contract['symbol'] === 'function'
                && typeof contract['decimals'] === 'function'
                && typeof contract['totalSupply'] === 'function'
                && typeof contract['balanceOf'] === 'function'
                && typeof contract['transfer'] === 'function'
                && typeof contract['transferFrom'] === 'function'
                && typeof contract['approve'] === 'function'
                && typeof contract['allowance'] === 'function'
              ) {
                isErc20 = true;
                tokenName = await contract['name()']();
                tokenSymbol = await contract['symbol()']();
                tokenDecimals = await contract['decimals()']();
                tokenTotalSupply = await contract['totalSupply()']();
              }
              
              const query = `UPDATE contract SET
                name = $1,
                verified = $2,
                source = $3,
                compiler_version = $4,
                arguments = $5,
                optimization = $6,
                runs = $7,
                target = $8,
                abi = $9,
                license = $10,
                is_erc20 = $11,
                token_name = $12,
                token_symbol = $13,
                token_decimals = $14,
                token_total_supply = $15
                WHERE contract_id = $16;
              `;
              const data = [
                name,
                isVerified,
                source,
                compilerVersion,
                args,
                optimization,
                runs,
                target,
                abi,
                license,
                isErc20,
                tokenName ? tokenName.toString() : null,
                tokenSymbol ? tokenSymbol.toString() : null,
                tokenDecimals ? tokenDecimals.toString(): null,
                tokenTotalSupply ? tokenTotalSupply.toString() : null,
                matchedContractId
              ];
              await parametrizedDbQuery(pool, query, data);
            }
            await provider.api.disconnect();
            await pool.query(query, data);
            res.send({
              status: true,
              message: 'Success, contract is verified'
            });
          }
        } else {
          res.send({
            status: false,
            message: 'Error, contract is not verified'
          });
        }
      } else {
        res.send({
          status: false,
          message: 'There was an error processing the request'
        });
      }
      await pool.end();
    }
  } catch (err) {
    res.status(500).send(err);
  }
});

app.post('/api/verificator/request-status', async (req: any, res) => {
  if(!req.params.id) {
    res.send({
      status: false,
      message: 'Input error'
    });
  } else {
    try {
      const requestId = req.params.id;
      const pool = await getPool();
      const data = [
        requestId
      ];
      const query = `
        SELECT
          id,
          contract_id
          status
          error_type
          error_message
        FROM contract_verification_request
        WHERE id = $1
      ;`;
      const dbres = await pool.query(query, data);
      if (dbres.rows.length > 0) {
        if (dbres.rows[0].status) {
          const id = dbres.rows[0].id;
          const requestStatus = dbres.rows[0].status;
          const contractId = dbres.rows[0].contract_id;
          const errorType = dbres.rows[0].error_type;
          const errorMessage = dbres.rows[0].error_message;
          res.send({
            status: true,
            message: 'Request found',
            data: {
              id,
              address: contractId,
              status: requestStatus,
              error_type: errorType,
              error_message: errorMessage,
            }
          });
        } else {
          res.send({
            status: false,
            message: 'Request not found'
          });
        }
      } else {
        res.send({
          status: false,
          message: 'Request not found'
        });
      }
      await pool.end();
    } catch (error) {
      res.send({
        status: false,
        message: 'Error'
      });
    }
  }
});

app.get('/api/staking/rewards', async (req: any, res) => {
  try {
    const pool = await getPool();
    const query = `
      SELECT
        block_number,
        data,
        event_index,
        method,
        phase,
        section,
        timestamp
      FROM event
      WHERE section = 'staking' AND method = 'Reward'
    ;`;
    const dbres = await pool.query(query);
    if (dbres.rows.length > 0) {
      res.send({
        status: true,
        message: 'Request found',
        data: {
          rows: dbres.rows,
        }
      });
    } else {
      res.send({
        status: false,
        message: 'Request not found'
      });
    }
    await pool.end();
  } catch (error) {
    res.send({
      status: false,
      message: 'Error'
    });
  }
});

app.get('/api/price/reef', async (req: any, res) => {
  const denom = 'reef-finance';
  await axios
    .get(
      `https://api.coingecko.com/api/v3/simple/price?ids=${denom}&vs_currencies=usd&include_24hr_change=true`
    )
    .then((response) => {
      res.send({
        status: true,
        message: 'Success',
        data: {
          usd: response.data[denom].usd,
          usd_24h_change: response.data[denom].usd_24h_change,
        }
      });
    })
    .catch((error) => {
      res.send({
        status: false,
        message: 'Error'
      });
    })
});


// Accepts account id or EVM address
app.post('/api/account/tokens', async (req: any, res) => {
  if(!req.body.account) {
    res.send({
      status: false,
      message: 'Input error, account parameter should be a valid Reef account id or EVM address'
    });
  } else {
    try {
      const pool = await getPool();
      const account = req.body.account;
      const data = [
        account
      ];
      const query = `
        SELECT
          th.contract_id,
          holder_account_id,
          holder_evm_address,
          balance,
          token_decimals,
          token_symbol
        FROM
          token_holder AS th,
          contract AS c
        WHERE
          (holder_account_id = $1 OR holder_evm_address = $1)
          AND th.contract_id = c.contract_id
      ;`;
      const dbres = await pool.query(query, data);
      if (dbres.rows.length > 0) {
        const balances = dbres.rows.map((token) => ({
          contract_id: token.contract_id,
          balance: token.balance,
          decimals: token.token_decimals,
          symbol: token.token_symbol,
        }));
        res.send({
          status: true,
          message: 'Success',
          data: {
            account_id: dbres.rows[0].holder_account_id,
            evm_address: dbres.rows[0].holder_evm_address,
            balances,
          }
        });
      } else {
        res.send({
          status: true,
          message: 'Success',
          data: {
            account_id: dbres.rows[0].holder_account_id,
            evm_address: dbres.rows[0].holder_evm_address,
            balances: [],
          }
        });
      }
      await pool.end();
    } catch (error) {
      res.send({
        status: false,
        message: 'Error'
      });
    }
  }
});


//
// Reef swap endpoints
//

// Get User Reef Balance
const USER_BALANCE_QUERY = `SELECT balance FROM token_holder WHERE (holder_account_id = $1 OR holder_evm_address = $1) AND contract_id = $2`;
const REEF_CONTRACT = '0x0000000000000000000000000000000001000000';
app.post('/api/user-balance', async (req: any, res) => {
  try {
    const userAddress = req.body.userAddress;
    const pool = await getPool();
    const dbres = await pool.query(USER_BALANCE_QUERY, [userAddress, REEF_CONTRACT]);
    res.send({
      balance: dbres.rows[0].balance
    });
    await pool.end();
  } catch (e) {
    res.send({
      balance: 0
    })
  }
});

app.listen(config.httpPort, () => 
  console.log(`Reef explorer API is listening on port ${config.httpPort}.`)
);
