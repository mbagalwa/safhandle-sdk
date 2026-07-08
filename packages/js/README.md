# @safrochaindev/safhandle

[![npm](https://img.shields.io/npm/v/@safrochaindev/safhandle.svg)](https://www.npmjs.com/package/@safrochaindev/safhandle)
[![license](https://img.shields.io/npm/l/@safrochaindev/safhandle.svg)](LICENSE)

TypeScript SDK for the [SafHandle](https://github.com/Safrochain-Org/safhandle-contract)
name service on Safrochain. Resolve a wallet address from a **name** and register
handles on-chain - with client-side validation that mirrors the contract, so bad
input is rejected before it costs gas.

- **Resolve** a `john.saf` name (or `@john`) to an `addr_safro...` address
- **Register / transfer / release** names with an exact-fee signer client
- **Validate** names locally (same rules as the on-chain contract)
- Ships **ESM + CommonJS + TypeScript types**, zero config

## Install

```bash
npm install @safrochaindev/safhandle
# or: yarn add @safrochaindev/safhandle   /   pnpm add @safrochaindev/safhandle
```

CosmJS (`@cosmjs/cosmwasm-stargate`, `@cosmjs/stargate`, `@cosmjs/proto-signing`,
`@cosmjs/encoding`) comes along as a dependency. **Node 18+**.

## Resolve an address (read-only)

```ts
import { SafHandleClient, SAFROCHAIN_TESTNET } from "@safrochaindev/safhandle";

// Testnet's contract address is baked into the SDK — just pass the RPC endpoint.
// (See "Choosing a network" below for mainnet and custom deployments.)
const client = await SafHandleClient.connect({
  network: "testnet",
  rpcEndpoint: SAFROCHAIN_TESTNET.rpcEndpoint,
});

// Resolve a name to its owner address.
await client.getAddress("john"); // -> { address, record_type: "name", normalized_key: "john.saf" }

// Just the address, or null if unregistered (no try/catch needed):
const addr = await client.lookup("john"); // string | null

// Reverse lookup: which name does an address own?
await client.getHandles("addr_safro1..."); // -> { name: "john.saf" | null }
```

### Choosing a network (`ConnectOptions`)

`connect()` takes **one** `ConnectOptions` object. The `network` field decides
where the contract address comes from — you never have to hardcode it for the
known networks:

| `network`   | You pass                              | Contract address used            |
| ----------- | ------------------------------------- | -------------------------------- |
| `"testnet"` | `rpcEndpoint`                         | pinned in the SDK                |
| `"mainnet"` | `rpcEndpoint`                         | pinned in the SDK                |
| `"custom"`  | `rpcEndpoint` **+** `contractAddress` | whatever you provide             |

**Fields**

- **`network`** — `"testnet" | "mainnet" | "custom"`. Picks which SafHandle
  contract the client talks to. `testnet`/`mainnet` use an address pinned in the
  SDK; `custom` lets you point at any deployment.
- **`rpcEndpoint`** — `string`, **required for every network.** The
  CometBFT/Tendermint RPC URL the client dials (handed straight to CosmJS'
  `CosmWasmClient.connect`) — e.g. `https://rpc.testnet.safrochain.com`, a local
  node at `http://localhost:26657`, or a same-origin proxy like `/api/rpc`. Only
  the contract address is pinned per network; the endpoint is always yours to pass.
- **`contractAddress`** — `string`, **only on `custom`, and required there.** The
  bech32 address of the deployed SafHandle contract (`addr_safro1…`). On
  `testnet`/`mainnet` it comes from `CONTRACT_ADDRESSES`, and passing it inline is
  a TypeScript error — the union has no such field on those two members, so you
  can't accidentally send an address that would be ignored.

> ℹ️ **mainnet** is not live yet — its address is a placeholder until the
> contract is deployed. Use `testnet` or `custom` for now.

The call returns a ready-to-use `SafHandleClient`; it opens the RPC connection
eagerly, so `await` it once and reuse the instance (see the read methods below).

#### When to use `custom`

Reach for `"custom"` whenever the contract you want to talk to is **not** one of
the pinned networks. You then provide both the endpoint and the address:

```ts
const client = await SafHandleClient.connect({
  network: "custom",
  rpcEndpoint: "http://localhost:26657",
  contractAddress: "addr_safro1...", // required — this is what makes it "custom"
});
```

Typical cases:

- **Local chain / devnet** — point at `http://localhost:26657` and the address
  printed when you instantiated the contract.
- **A specific deployment** — an older or newer contract than the one baked into
  the SDK, or an unlisted one.
- **Behind an RPC proxy** — e.g. a browser app that calls a same-origin
  `/api/rpc` route to avoid CORS, aimed at the contract of your choice.

The full type, for reference:

```ts
type ConnectOptions =
  | { network: "testnet"; rpcEndpoint: string }
  | { network: "mainnet"; rpcEndpoint: string }
  | { network: "custom"; rpcEndpoint: string; contractAddress: string };
```

### Read methods

| Method                | Returns                                            |
| --------------------- | -------------------------------------------------- |
| `getAddress(input)`   | `GetAddressResponse` - resolve a name              |
| `lookup(input)`       | `string \| null` - address, or `null` if not found |
| `resolveName(name)`   | `string` - address (name only)                     |
| `getHandles(address)` | `{ name }` - reverse lookup                        |
| `getNameRecord(name)` | full record incl. owner and registration height    |
| `getConfig()`         | fee, denom, governance admin                       |

## Register (writes)

Writes need a signer. The client validates and normalizes input locally (same
rules as the contract) and attaches the exact fee fetched from config.

```ts
import {
  SafHandleSigningClient,
  SAFROCHAIN_TESTNET,
} from "@safrochaindev/safhandle";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";

const signer = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
  prefix: SAFROCHAIN_TESTNET.addressPrefix, // "addr_safro"
});

const client = await SafHandleSigningClient.connectWithSigner(
  SAFROCHAIN_TESTNET.rpcEndpoint,
  signer,
  SAFROCHAIN_TESTNET.contractAddress, // pinned testnet contract
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
} from "@safrochaindev/safhandle";

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
npm run build      # tsc -> dist/
npm run typecheck  # tsc --noEmit
```

## Tests

Tests run against the built `dist/` (so what ships is what's tested).

```bash
npm test              # unit + write-path (offline, deterministic)
npm run test:integration   # live reads against safro-testnet-1
```

- **Unit** - `normalizeName` / `parseInput` parity with the contract's
  `validation.rs`, and the `isNotFound` heuristic.
- **Write path** - CosmJS is stubbed to assert the exact `ExecuteMsg` and funds
  the SDK submits (no broadcast), plus that invalid input throws before any
  network call.
- **Integration** - live `getConfig` / `getAddress` / `lookup` / `resolveName` /
  `getHandles` / `getNameRecord`. Skipped unless `SAFHANDLE_INTEGRATION=1`.

## Examples

- [`examples/resolve.ts`](examples/resolve.ts) - resolve a name
- [`examples/register.ts`](examples/register.ts) - register a name from a mnemonic

Run with `npx tsx examples/resolve.ts john`.

## License

[MIT](LICENSE) (c) Safrochain
