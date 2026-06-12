# Example: React Hook for Name Lookup

Custom React hook for SAFLink name resolution in dApp UIs. Markdown walkthrough — implementation in Phase 2.

## Goal

Provide `useSafLinkAddress(input)` that returns `{ address, loading, error }` for any React component.

## Target API

```typescript
function useSafLinkAddress(
  input: string,
  options?: { network?: string; enabled?: boolean }
): {
  result: ResolveResult | null;
  loading: boolean;
  error: SafLinkError | null;
  refetch: () => void;
}
```

## Usage

```tsx
import { useSafLinkAddress } from '@safrochain/saflink/react';

function SendForm() {
  const [to, setTo] = useState('');
  const { result, loading, error } = useSafLinkAddress(to, {
    enabled: to.length >= 3,
  });

  return (
    <div>
      <input value={to} onChange={(e) => setTo(e.target.value)} placeholder="john or +243..." />
      {loading && <span>Resolving...</span>}
      {error && <span>{error.message}</span>}
      {result && (
        <p>
          Sends to {result.normalizedKey} → {result.address}
        </p>
      )}
    </div>
  );
}
```

## Hook implementation sketch

```typescript
export function useSafLinkAddress(input: string, options = {}) {
  const [result, setResult] = useState<ResolveResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<SafLinkError | null>(null);

  const client = useMemo(
    () => new SafLink({ network: options.network ?? 'safrochain-testnet' }),
    [options.network]
  );

  useEffect(() => {
    if (!options.enabled && options.enabled !== undefined) return;
    if (!input) {
      setResult(null);
      return;
    }

    const timer = setTimeout(async () => {
      setLoading(true);
      setError(null);
      try {
        setResult(await client.getAddress(input));
      } catch (err) {
        setError(err as SafLinkError);
        setResult(null);
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [input, client, options.enabled]);

  return { result, loading, error, refetch: () => { /* ... */ } };
}
```

## Package plan

Future optional package: `@safrochain/saflink-react` to keep core SDK free of React peer dependency.

## Related

- [INTEGRATION_GUIDE.md](../../docs/INTEGRATION_GUIDE.md)
- [API_REFERENCE.md](../../docs/API_REFERENCE.md)
