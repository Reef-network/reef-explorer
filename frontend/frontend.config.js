export const network = {
  id: 'reef-testnet',
  name: 'Testnet',
  tokenSymbol: 'REEF',
  tokenDecimals: 18,
  ss58Format: 42,
  coinGeckoDenom: 'reef-finance',
  nodeWs: 'wss://localhost:30333',
  backendWs: 'wss://testnet.reefscan.com/api/v3',
  gqlWs: 'ws://localhost:8080/v1/graphql',
  gqlHttp: 'http://localhost:8080/v1/graphql',
  backendHttp: 'http://localhost:8000',
  verificatorApi: 'http://localhost:8000/api/verificator',
  googleAnalytics: '',
  theme: '@/assets/scss/themes/reef.scss',
}
export const paginationOptions = [10, 20, 50, 100]
