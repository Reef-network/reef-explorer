export const network = {
  id: 'reef-testnet',
  name: 'Testnet',
  tokenSymbol: 'REEF',
  tokenDecimals: 18,
  ss58Format: 42,
  coinGeckoDenom: 'reef-finance',
  nodeWs: 'ws://substrate-node:9944',
  backendWs: 'ws://graphql:8080/v1/graphql',
  backendHttp: 'http://graphql:8080/v1/graphql',
  verificatorApi: 'http://api:8000/api/verificator',
  googleAnalytics: '',
  theme: '@/assets/scss/themes/reef.scss',
}
export const paginationOptions = [10, 20, 50, 100]
