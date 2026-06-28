# API Reference

Target API for `@safrochain/safhandle`. Aligns with [contract CONTRACT_API.md](https://github.com/Safrochain-Org/safhandle-contract/blob/main/docs/CONTRACT_API.md).

## SafHandle class

```typescript
import { SafHandle } from '@safrochain/safhandle';

const client = new SafHandle(options: SafHandleOptions);
```

### SafHandleOptions

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `network` | `'safrochain-testnet' \| 'safrochain-mainnet'` | Yes* | Network slug |
| `rpcUrl` | `string` | No | Override RPC endpoint |
| `contractAddress` | `string` | No | Override contract address |
| `restUrl` | `string` | No | Override REST endpoint |

\* Alternatively pass explicit `rpcUrl` + `contractAddress`.

## Query methods

### getAddress(input)

Resolve a short name or E.164 phone number.

```typescript
getAddress(input: string): Promise<ResolveResult>
```

**Parameters:**

| Name | Type | Description |
| --- | --- | --- |
| `input` | `string` | `john`, `john.saf`, or `+243899123456` |

**Returns:** `ResolveResult`

```typescript
interface ResolveResult {
  address: string;           // addr_safro1...
  recordType: 'name' | 'phone';
  normalizedKey: string;     // john.saf or +243...
  verified: boolean | null;  // null for names; boolean for phones
}
```

**Throws:** `SafHandleNotFoundError`, `SafHandleInvalidInputError`

---

### getConfig()

Read current contract fees and configuration.

```typescript
getConfig(): Promise<SafHandleConfig>
```

```typescript
interface SafHandleConfig {
  nameRegistrationFeeUsaf: string;
  phoneLinkFeeUsaf: string;
  devModuleWallet: string;
  nativeDenom: string;
}
```

---

### resolveName(name)

Name-only resolution (no phone routing).

```typescript
resolveName(name: string): Promise<ResolveResult>
```

---

### resolvePhone(phone)

Phone-only resolution.

```typescript
resolvePhone(phone: string): Promise<ResolveResult>
```

## Execute methods (require signer)

### registerName(name, options)

Register a short name for the signer's address.

```typescript
registerName(
  name: string,
  options: ExecuteOptions
): Promise<TxResult>
```

**Fee:** 50 SAF (`50000000` usaf) by default.

---

### linkPhone(phone, options)

Link an E.164 phone to the signer's address.

```typescript
linkPhone(
  phone: string,
  options: ExecuteOptions
): Promise<TxResult>
```

**Fee:** 100 SAF (`100000000` usaf) by default.

---

### transferName(name, newOwner, options)

Transfer name ownership.

```typescript
transferName(
  name: string,
  newOwner: string,
  options: ExecuteOptions
): Promise<TxResult>
```

---

### releaseName(name, options)

Release a name back to the pool.

```typescript
releaseName(name: string, options: ExecuteOptions): Promise<TxResult>
```

## ExecuteOptions

```typescript
interface ExecuteOptions {
  signer: OfflineSigner;
  fee?: string;          // usaf amount; defaults from config
  memo?: string;
  gas?: 'auto' | number;
}
```

## Validation utilities

```typescript
import {
  normalizeName,
  isValidName,
  isValidPhone,
  normalizePhone,
} from '@safrochain/safhandle';

normalizeName('John');        // 'john.saf'
isValidPhone('+243899123456'); // true
```

| Function | Description |
| --- | --- |
| `normalizeName(input)` | Apply name rules from contract spec |
| `isValidName(input)` | Boolean validation |
| `normalizePhone(input)` | Strip formatting, enforce E.164 |
| `isValidPhone(input)` | Boolean E.164 check |
| `isSafroAddress(addr)` | Validate `addr_safro` bech32 |

## Error types

| Error | Code | When |
| --- | --- | --- |
| `SafHandleNotFoundError` | `NOT_FOUND` | Name or phone not registered |
| `SafHandleInvalidInputError` | `INVALID_INPUT` | Failed validation |
| `SafHandleInsufficientFeeError` | `INSUFFICIENT_FEE` | Wrong fee amount attached |
| `SafHandleNetworkError` | `NETWORK` | RPC failure |
| `SafHandleContractError` | `CONTRACT` | On-chain contract error |

See [ERROR_HANDLING.md](./ERROR_HANDLING.md).

## Planned exports

```typescript
export { SafHandle } from './client';
export type { SafHandleOptions, ResolveResult, SafHandleConfig, ExecuteOptions, TxResult };
export * from './validation';
export * from './errors';
export { networks } from './networks';
```
