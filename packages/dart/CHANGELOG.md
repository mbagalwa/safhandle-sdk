# Changelog

All notable changes to this package are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[SemVer](https://semver.org/spec/v2.0.0.html).

## 0.2.1-beta

### Added

- Initial Dart/Flutter port of the SafHandle SDK, matching the TypeScript SDK's
  public surface:
  - `SafHandleClient` — read-only smart queries over the REST/LCD gateway
    (`getAddress`, `lookup`, `resolveName`, `getHandles`, `getNameRecord`,
    `getConfig`).
  - `SafHandleSigningClient` + pluggable `SafHandleSigner` — `registerName`
    (exact fee from config), `transferName`, `releaseName`.
  - Validation helpers mirroring the contract's `validation.rs`
    (`normalizeName`, `parseInput`, `isSafrochainAddress`, `toDisplayName`).
  - `SafHandleError` / `SafHandleErrorCode` and the `isNotFound` heuristic.
  - Testnet/mainnet network presets with the pinned testnet contract address.
- Dependency-free bech32 checksum verification for address validation.
- Unit tests for validation parity, the read path, and the write path.
