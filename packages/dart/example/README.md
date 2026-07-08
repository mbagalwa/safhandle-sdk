# Examples

- [`resolve.dart`](resolve.dart) — resolve a name to an address (read-only, runnable).
- [`register.dart`](register.dart) — register a name via a `SafHandleSigner` (shows the write path; wire a real signer to run it).

```bash
dart run example/resolve.dart john
```

See the package [README](../README.md) for Flutter widget usage and for how to
implement a `SafHandleSigner` on top of a Cosmos Dart signing library.
