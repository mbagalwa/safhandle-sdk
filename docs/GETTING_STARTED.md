# Getting Started

Quick guide to integrating SafHandle resolution into your application. **Implementation is coming in a later release** — this document describes the target developer experience.

## Prerequisites

- Node.js 20+
- A Safrochain RPC endpoint (testnet or mainnet)
- SafHandle contract address (published in [config/](../config/) after deployment)

## Installation (future)

```bash
npm install @safrochain/safhandle
```

## Configuration

Copy environment template:

```bash
cp .env.example .env
```

| Variable | Default | Description |
| --- | --- | --- |
| `SAFHANDLE_NETWORK` | `safrochain-testnet` | Network slug |
| `SAFHANDLE_CONTRACT_ADDRESS` | From config JSON | Override contract address |
| `SAFHANDLE_RPC_URL` | From config JSON | Override RPC |

## Basic usage

```js
import { SafHandle } from '@safrochain/safhandle';

const safHandle = new SafHandle({
  network: 'safrochain-testnet',
});

// Resolve short name
const result = await safHandle.getAddress('john');
console.log(result.address);       // addr_safro1...
console.log(result.normalizedKey); // john.saf
console.log(result.recordType);  // name

// Resolve phone
const phone = await safHandle.getAddress('+243899123456');
console.log(phone.verified);       // false (Phase 1)
console.log(phone.recordType);     // phone
```

## Register a name (future)

Requires a connected wallet with signing capability:

```js
const tx = await safHandle.registerName('john.saf', {
  signer: offlineSigner,
  fee: '50000000', // 50 SAF in usaf
});
await tx.wait();
```

## Register a phone (future)

```js
const tx = await safHandle.linkPhone('+243899123456', {
  signer: offlineSigner,
  fee: '100000000', // 100 SAF in usaf
});
await tx.wait();
```

## Network selection

| Slug | Chain ID | Config file |
| --- | --- | --- |
| `safrochain-testnet` | `safro-testnet-1` | [config/testnet.json](../config/testnet.json) |
| `safrochain-mainnet` | `safrochain-1` | [config/mainnet.json](../config/mainnet.json) |

See [NETWORKS.md](./NETWORKS.md) for the full schema.

## Next steps

- [API_REFERENCE.md](./API_REFERENCE.md) — full method list
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) — dApp patterns
- [examples/node-resolve](../examples/node-resolve/README.md) — walkthrough
