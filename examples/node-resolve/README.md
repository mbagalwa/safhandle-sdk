# Example: Node.js Name Resolution

Resolve a SAFLink short name from a Node.js script. **Runnable code coming in Phase 2** — this walkthrough describes the target flow.

## Goal

Given input `john`, print the resolved `addr_safro` address on testnet.

## Prerequisites

- Node.js 20+
- `@safrochain/saflink` installed (future)
- SAFLink contract deployed on testnet

## Steps

### 1. Configure environment

```bash
cp .env.example .env
```

Set:

```env
SAFLINK_NETWORK=safrochain-testnet
```

### 2. Create resolve script

```javascript
import { SafLink } from '@safrochain/saflink';

const safLink = new SafLink({ network: 'safrochain-testnet' });

const input = process.argv[2] ?? 'john';
const result = await safLink.getAddress(input);

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
import { SafLinkNotFoundError } from '@safrochain/saflink';

try {
  await safLink.getAddress('nobody');
} catch (err) {
  if (err instanceof SafLinkNotFoundError) {
    console.error('Name not registered.');
    process.exit(1);
  }
  throw err;
}
```

## Related

- [GETTING_STARTED.md](../../docs/GETTING_STARTED.md)
- [API_REFERENCE.md](../../docs/API_REFERENCE.md)
