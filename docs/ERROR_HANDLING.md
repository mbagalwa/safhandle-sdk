# Error Handling

Error types and recovery strategies for `@safrochain/saflink`.

## Error hierarchy

```text
SafLinkError (base)
├── SafLinkNotFoundError
├── SafLinkInvalidInputError
├── SafLinkInsufficientFeeError
├── SafLinkNetworkError
├── SafLinkContractError
└── SafLinkVerificationError (Phase 2)
    ├── VerificationPendingError
    ├── VerificationFailedError
    └── VerificationRateLimitError
```

## Error reference

### SafLinkNotFoundError

**Code:** `NOT_FOUND`

Name or phone is not registered.

```typescript
try {
  await safLink.getAddress('unknown');
} catch (err) {
  if (err instanceof SafLinkNotFoundError) {
    showMessage('Name not found. Check spelling or ask recipient to register.');
  }
}
```

---

### SafLinkInvalidInputError

**Code:** `INVALID_INPUT`

Input fails name or phone validation.

| Cause | Example |
| --- | --- |
| Too short | `a` |
| Reserved name | `safrochain` |
| Invalid phone | `243899123456` (missing `+`) |

---

### SafLinkInsufficientFeeError

**Code:** `INSUFFICIENT_FEE`

Execute message attached wrong fee amount.

**Recovery:** Call `getConfig()` and use current fee values.

---

### SafLinkNetworkError

**Code:** `NETWORK`

RPC unreachable, timeout, or malformed response.

**Recovery:** Retry with exponential backoff; fall back to alternate RPC.

---

### SafLinkContractError

**Code:** `CONTRACT`

On-chain contract returned an error (name taken, not owner, etc.).

| Contract error | SDK mapping |
| --- | --- |
| `NameTaken` | `SafLinkContractError` with `reason: 'name_taken'` |
| `PhoneTaken` | `reason: 'phone_taken'` |
| `Unauthorized` | `reason: 'unauthorized'` |

## User-facing messages

| Error | Suggested message |
| --- | --- |
| `NOT_FOUND` | "We couldn't find that name or number on SAFLink." |
| `INVALID_INPUT` | "Please enter a valid name (e.g. john) or phone (+243...)." |
| `INSUFFICIENT_FEE` | "Registration fee has changed. Please try again." |
| `NETWORK` | "Can't reach Safrochain right now. Try again shortly." |
| Unverified phone | "This phone isn't verified yet. Proceed with caution." |

## Logging

| Log | OK | Not OK |
| --- | --- | --- |
| Normalized key | Yes | — |
| Resolved address | Yes (dev only) | Production analytics |
| Phone numbers | Never | — |
| Private keys | Never | — |

## Related

- [API_REFERENCE.md](./API_REFERENCE.md)
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)
