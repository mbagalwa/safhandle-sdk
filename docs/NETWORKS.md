# Networks

Network configuration schema for `@safrochain/saflink`. Config files live in [config/](../config/).

## Supported networks

| Slug | Chain ID | Config | Role |
| --- | --- | --- | --- |
| `safrochain-testnet` | `safro-testnet-1` | [testnet.json](../config/testnet.json) | Testing |
| `safrochain-mainnet` | `safrochain-1` | [mainnet.json](../config/mainnet.json) | Production |

## Config schema

```typescript
interface NetworkConfig {
  name: string;
  chainName: string;
  chainId: string;
  bech32Prefix: string;
  addressRegex: string;
  coinDenom: string;
  coinMinimalDenom: string;
  coinDecimals: number;
  slip44: number;
  rpc: string;
  rest: string;
  ws: string;
  explorer: string;
  contractAddress: string;
  gasPrice: string;
  gasPriceSteps: { low: number; average: number; high: number };
  role: 'testing' | 'production';
  saflink: SafLinkNetworkConfig;
}

interface SafLinkNetworkConfig {
  nameRegistrationFeeUsaf: string;  // "50000000" = 50 SAF
  phoneLinkFeeUsaf: string;         // "100000000" = 100 SAF
  devModuleWallet: string;
  governanceModule: string;
}
```

## Loading config

```typescript
import { SafLink, networks } from '@safrochain/saflink';

const testnet = networks['safrochain-testnet'];
const client = new SafLink({ network: 'safrochain-testnet' });
```

## Environment overrides

| Env var | Overrides |
| --- | --- |
| `SAFLINK_NETWORK` | Default network slug |
| `SAFLINK_CONTRACT_ADDRESS` | `contractAddress` |
| `SAFLINK_RPC_URL` | `rpc` |
| `SAFLINK_REST_URL` | `rest` |

## Chain constants

| Constant | Value |
| --- | --- |
| Bech32 prefix | `addr_safro` |
| Display denom | `SAF` |
| Minimal denom | `usaf` |
| Decimals | 6 |

## Endpoints

| Network | RPC | REST |
| --- | --- | --- |
| Testnet | `https://rpc.testnet.safrochain.com` | `https://rest.testnet.safrochain.com` |
| Mainnet | `https://rpc.safrochain.com` | `https://api.safrochain.com` |

## Contract address updates

After deployment, update `contractAddress` in both repos:

- [saflink-contract/config/](../config/)
- [saflink-sdk/config/](../config/)

Publish a coordinated release when the address changes.

## Fee defaults

| Fee | usaf | SAF |
| --- | --- | --- |
| Name registration | `50000000` | 50 |
| Phone link | `100000000` | 100 |

Fees on-chain may differ if governance updates them. Always call `getConfig()` before execute methods.
