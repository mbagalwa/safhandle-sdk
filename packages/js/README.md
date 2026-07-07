# @safrochain/safhandle

[![npm](https://img.shields.io/npm/v/@safrochain/safhandle.svg)](https://www.npmjs.com/package/@safrochain/safhandle)
[![license](https://img.shields.io/npm/l/@safrochain/safhandle.svg)](LICENSE)

TypeScript SDK for the [SafHandle](https://github.com/Safrochain-Org/safhandle-contract)
name service on Safrochain. Resolve a wallet address from a **name** and register
handles on-chain — with client-side validation that mirrors the contract, so bad
input is rejected before it costs gas.

- 🔎 **Resolve** a `john.saf` name (or `@john`) to an `addr_safro…` address
- ✍️ **Register / transfer / release** names with an exact-fee signer client
- 🧰 **Validate** names locally (same rules as the on-chain contract)
- 📦 Ships **ESM + CommonJS + TypeScript types**, zero config

## Install

```bash
npm install @safrochain/safhandle
# or: yarn add @safrochain/safhandle   /   pnpm add @safrochain/safhandle
```

CosmJS (`@cosmjs/cosmwasm-stargate`, `@cosmjs/stargate`, `@cosmjs/proto-signing`,
`@cosmjs/encoding`) comes along as a dependency. **Node 18+**.

## Resolve an address (read-only)

```ts
import { SafHandleClient, SAFROCHAIN_TESTNET } from "@safrochain/safhandle";

const client = await SafHandleClient.connect(
  SAFROCHAIN_TESTNET.rpcEndpoint,
  CONTRACT_ADDRESS, // the deployed safhandle contract (addr_safro1...)
);

// Resolve a name to its owner address.
await client.getAddress("john"); // → { address, record_type: "name", normalized_key: "john.saf" }

// Just the address, or null if unregistered (no try/catch needed):
const addr = await client.lookup("john"); // string | null

// Reverse lookup: which name does an address own?
await client.getHandles("addr_safro1..."); // → { name: "john.saf" | null }
```

### Read methods

| Method                | Returns                                            |
| --------------------- | -------------------------------------------------- |
| `getAddress(input)`   | `GetAddressResponse` — resolve a name              |
| `lookup(input)`       | `string \| null` — address, or `null` if not found |
| `resolveName(name)`   | `string` — address (name only)                     |
| `getHandles(address)` | `{ name }` — reverse lookup                        |
| `getNameRecord(name)` | full record incl. owner and registration height    |
| `getConfig()`         | fee, denom, governance admin                       |

## Register (writes)

Writes need a signer. The client validates and normalizes input locally (same
rules as the contract) and attaches the exact fee fetched from config.

```ts
import {
  SafHandleSigningClient,
  SAFROCHAIN_TESTNET,
} from "@safrochain/safhandle";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";

const signer = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
  prefix: SAFROCHAIN_TESTNET.addressPrefix, // "addr_safro"
});

const client = await SafHandleSigningClient.connectWithSigner(
  SAFROCHAIN_TESTNET.rpcEndpoint,
  signer,
  CONTRACT_ADDRESS,
);

await client.registerName("my-name"); // attaches name fee from config
await client.transferName("my-name", "addr_safro1...");
await client.releaseName("my-name");
```

`SafHandleSigningClient` extends `SafHandleClient`, so all read methods are
available on it too.

## Validation helpers

Exposed for pre-flight checks (mirror `validation.rs`):

```ts
import {
  normalizeName,
  parseInput,
  isSafrochainAddress,
} from "@safrochain/safhandle";

normalizeName("  John  "); // "john.saf"
normalizeName("@john"); // "john.saf"  (@ is a display marker)
normalizeName("john@x.com"); // throws SafHandleError { code: "EmailNotAllowed" }
parseInput("@john"); // { kind: "name", value: "john.saf" }
parseInput("addr_safro1..."); // { kind: "address", value: "addr_safro1..." }
```

Invalid input throws a `SafHandleError` with a `.code` (`InvalidName`,
`EmailNotAllowed`, `ReservedName`, `InvalidInput`, `NotFound`).

## Build

```bash
npm install
npm run build      # tsc → dist/
npm run typecheck  # tsc --noEmit
```

## Tests

Tests run against the built `dist/` (so what ships is what's tested).

```bash
npm test              # unit + write-path (offline, deterministic)
npm run test:integration   # live reads against safro-testnet-1
```

- **Unit** — `normalizeName` / `parseInput` parity with the contract's
  `validation.rs`, and the `isNotFound` heuristic.
- **Write path** — CosmJS is stubbed to assert the exact `ExecuteMsg` and funds
  the SDK submits (no broadcast), plus that invalid input throws before any
  network call.
- **Integration** — live `getConfig` / `getAddress` / `lookup` / `resolveName` /
  `getHandles` / `getNameRecord`. Skipped unless `SAFHANDLE_INTEGRATION=1`.

## Examples

- [`examples/resolve.ts`](examples/resolve.ts) — resolve a name
- [`examples/register.ts`](examples/register.ts) — register a name from a mnemonic

Run with `npx tsx examples/resolve.ts john`.

## License

[MIT](LICENSE) © Safrochain
