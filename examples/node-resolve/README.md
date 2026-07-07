# Example: Node.js Name Resolution

Resolve a SafHandle short name from a Node.js script. **Runnable code coming in Phase 2** — this walkthrough describes the target flow.

## Goal

Given input `john`, print the resolved `addr_safro` address on testnet.

## Prerequisites

- Node.js 20+
- `@safrochaindev/safhandle` installed (future)
- SafHandle contract deployed on testnet

## Steps

### 1. Configure environment

```bash
cp .env.example .env
```

Set:

```env
SAFHANDLE_NETWORK=safrochain-testnet
```

### 2. Create resolve script

```javascript
import { SafHandle } from '@safrochaindev/safhandle';

const safHandle = new SafHandle({ network: 'safrochain-testnet' });

const input = process.argv[2] ?? 'john';
const result = await safHandle.getAddress(input);

console.log(`Input:      ${input}`);
console.log(`Normalized: ${result.normalizedKey}`);
console.log(`Type:       ${result.recordType}`);
console.log(`Address:    ${result.address}`);
```

### 3. Run

```bash
node resolve.mjs john
# Input:      john
# Normalized: john.saf
# Type:       name
# Address:    addr_safro1...

node resolve.mjs +243899123456
# Type:       phone
# Verified:   false
```

## Error handling

```javascript
import { SafHandleNotFoundError } from '@safrochaindev/safhandle';

try {
  await safHandle.getAddress('nobody');
} catch (err) {
  if (err instanceof SafHandleNotFoundError) {
    console.error('Name not registered.');
    process.exit(1);
  }
  throw err;
}
```

## Related

- [GETTING_STARTED.md](../../docs/GETTING_STARTED.md)
- [API_REFERENCE.md](../../docs/API_REFERENCE.md)
