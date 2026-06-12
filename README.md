<p align="center">
  <strong>SAFLink SDK</strong><br>
  TypeScript client for short names and phone links on Safrochain
</p>

<p align="center">
  <a href="https://github.com/Safrochain-Org/saflink-sdk/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://github.com/Safrochain-Org/saflink-sdk/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/Safrochain-Org/saflink-sdk/ci.yml?branch=main" alt="CI">
  </a>
  <a href="https://safrochain.com">
    <img src="https://img.shields.io/badge/built%20on-Safrochain-6C3CE0" alt="Built on Safrochain">
  </a>
</p>

---

> **Status: Specification / Documentation phase.** Package implementation and npm publish will follow in a later milestone.

**SAFLink SDK** lets any wallet or dApp resolve short names and phone numbers to `addr_safro` wallet addresses on Safrochain.

```js
import { SafLink } from '@safrochain/saflink';

const safLink = new SafLink({ network: 'safrochain-testnet' });
const address = await safLink.getAddress('john');
const address2 = await safLink.getAddress('+243899123456');
```

## Why use the SDK

| Without SAFLink | With SAFLink SDK |
| --- | --- |
| Users paste 50+ character addresses | Users type `john` or `+243899123456` |
| Each app builds its own CosmWasm queries | One typed client for all integrators |
| Inconsistent name normalization | Shared validation rules |

## Documentation

| Document | Contents |
| --- | --- |
| [docs/README.md](./docs/README.md) | Documentation index |
| [GETTING_STARTED.md](./docs/GETTING_STARTED.md) | Install and first resolve |
| [API_REFERENCE.md](./docs/API_REFERENCE.md) | `SafLink` client methods |
| [INTEGRATION_GUIDE.md](./docs/INTEGRATION_GUIDE.md) | dApp integration patterns |
| [WALLET_INTEGRATION.md](./docs/WALLET_INTEGRATION.md) | Keplr, Leap, signing flows |
| [PHONE_VERIFICATION.md](./docs/PHONE_VERIFICATION.md) | Phase 2 verification |
| [NETWORKS.md](./docs/NETWORKS.md) | Network config schema |
| [ERROR_HANDLING.md](./docs/ERROR_HANDLING.md) | Error types and recovery |
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | SDK ↔ contract ↔ chain |
| [ROADMAP.md](./docs/ROADMAP.md) | Publish timeline |

## Examples

| Example | Description |
| --- | --- |
| [node-resolve](./examples/node-resolve/README.md) | Resolve a name from Node.js |
| [browser-wallet](./examples/browser-wallet/README.md) | Browser wallet send flow |
| [react-hook](./examples/react-hook/README.md) | React hook for name lookup |

Examples are markdown walkthroughs in this phase (no runnable code yet).

## Fees (via contract)

| Action | Default fee |
| --- | --- |
| Register short name | 50 SAF |
| Link phone | 100 SAF |

See [contract fees doc](https://github.com/Safrochain-Org/saflink-contract/blob/main/docs/FEES_AND_GOVERNANCE.md).

## Related repositories

| Repository | Description |
| --- | --- |
| [saflink-contract](https://github.com/Safrochain-Org/saflink-contract) | CosmWasm registry specification |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Security: [SECURITY.md](./SECURITY.md).

## License

[MIT](./LICENSE) — Copyright (c) 2026 Safrochain
