# safhandle (Dart / Flutter)

[![pub](https://img.shields.io/pub/v/safhandle.svg)](https://pub.dev/packages/safhandle)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Dart/Flutter SDK for the [SafHandle](https://github.com/Safrochain-Org/safhandle-contract)
name service on Safrochain. Resolve a wallet address from a **name** and register
handles on-chain — with client-side validation that mirrors the contract, so bad
input is rejected before it costs gas.

This is a faithful port of the TypeScript SDK
([`@safrochaindev/safhandle`](../js/README.md)); the public surface, validation
rules, and message shapes match one-to-one.

- **Resolve** a `john.saf` name (or `@john`) to an `addr_safro...` address
- **Register / transfer / release** names via a pluggable signer with the exact fee
- **Validate** names locally (same rules as the on-chain contract)
- Pure Dart — runs on Flutter (mobile, web, desktop) and server Dart. Only
  dependency: `http`.

## Install

```yaml
# pubspec.yaml
dependencies:
  safhandle: ^0.1.0
```

```bash
dart pub add safhandle   # or: flutter pub add safhandle
```

**Dart SDK 3.4+.**

## Resolve an address (read-only)

The read client talks to the chain's **REST/LCD** gateway
(`/cosmwasm/wasm/v1/...`), so there is no native crypto dependency and it works
on Flutter web too. Testnet's contract address is baked in — just point at the
REST endpoint (defaults to the public testnet gateway).

```dart
import 'package:safhandle/safhandle.dart';

final client = SafHandleClient.connect(ConnectOptions.testnet());

// Resolve a name to its owner address.
final record = await client.getAddress('john');
// record.address, record.recordType == 'name', record.normalizedKey == 'john.saf'

// Just the address, or null if unregistered (no try/catch needed):
final String? addr = await client.lookup('john');

// Reverse lookup: which name does an address own?
final handles = await client.getHandles('addr_safro1...'); // handles.name: String?

client.close(); // dispose the internal HTTP client when done
```

### Choosing a network (`ConnectOptions`)

`connect()` takes one `ConnectOptions`. Pick where the contract address comes
from — you never have to hardcode it for the known networks:

| Constructor                    | You pass                                | Contract address used |
| ------------------------------ | --------------------------------------- | --------------------- |
| `ConnectOptions.testnet()`     | (optional `restEndpoint`)               | pinned in the SDK     |
| `ConnectOptions.mainnet()`     | (optional `restEndpoint`)               | pinned in the SDK     |
| `ConnectOptions.custom(...)`   | `restEndpoint` **+** `contractAddress`  | whatever you provide  |

`restEndpoint` defaults to the public gateway for `testnet`/`mainnet`; override
it to hit a local node (`http://localhost:1317`) or a same-origin proxy.

> ℹ️ **mainnet** is not live yet — its contract address is a placeholder. Use
> `testnet` or `custom` for now.

Reach for `custom` for a local chain/devnet, a specific (older/newer/unlisted)
deployment, or when you route through an RPC proxy:

```dart
final client = SafHandleClient.connect(
  ConnectOptions.custom(
    restEndpoint: 'http://localhost:1317',
    contractAddress: 'addr_safro1...',
  ),
);
```

### Read methods

| Method                   | Returns                                             |
| ------------------------ | --------------------------------------------------- |
| `getAddress(input)`      | `GetAddressResponse` — resolve a name               |
| `lookup(input)`          | `String?` — address, or `null` if not found         |
| `resolveName(name)`      | `String` — address (name only)                      |
| `getHandles(address)`    | `HandlesResponse` — reverse lookup (`name` nullable) |
| `getNameRecord(name)`    | full record incl. owner and registration height     |
| `getConfig()`            | fee, denom, governance admin                         |

## Register (writes): bring your own signer

Writes need a signer. Rather than bundle a full Cosmos signing/protobuf stack,
the SDK keeps the exact same split as the JS client (which injects a CosmJS
`OfflineSigner`): **the SDK owns validation, message construction, and the exact
fee; you plug in a `SafHandleSigner`** that signs and broadcasts a single
`MsgExecuteContract`.

```dart
abstract class SafHandleSigner {
  String get sender; // addr_safro...
  Future<ExecuteResult> execute({
    required String contract,
    required Map<String, dynamic> msg,
    List<Coin> funds,
    String? memo,
  });
}
```

Implement it on top of your Cosmos stack — e.g. a
[`cosmos_sdk`](https://pub.dev/packages/cosmos_sdk)/`alan`-based signer, or a
mobile wallet reached over WalletConnect. Then:

```dart
final client = SafHandleSigningClient.connect(
  signer: mySigner,
  options: ConnectOptions.testnet(),
);

await client.registerName('my-name');              // attaches the name fee from config
await client.transferName('my-name', 'addr_safro1...');
await client.releaseName('my-name');
```

`SafHandleSigningClient` extends `SafHandleClient`, so all read methods are
available on it too. `registerName` fetches the exact fee from the contract
config unless you pass `WriteOptions(fee: Coin('usaf', '...'))`.

## Validation helpers

Exposed for pre-flight checks (mirror the contract's `validation.rs`):

```dart
normalizeName('  John  ');    // 'john.saf'
normalizeName('@john');       // 'john.saf'  (@ is a display marker)
normalizeName('john@x.com');  // throws SafHandleError(emailNotAllowed)

parseInput('@john');          // ParsedInput(name, 'john.saf')
parseInput('addr_safro1...'); // ParsedInput(address, 'addr_safro1...')

isSafrochainAddress('addr_safro1...'); // true (bech32 checksum verified)
```

Invalid input throws a `SafHandleError` with a `.code`
(`invalidName`, `emailNotAllowed`, `reservedName`, `invalidInput`, `notFound`).

## Flutter usage

The package has no `flutter` dependency, so it drops straight into any Flutter
app:

```dart
class NameResolver {
  final _client = SafHandleClient.connect(ConnectOptions.testnet());

  Future<String?> resolve(String input) => _client.lookup(input);
  void dispose() => _client.close();
}
```

Because reads go over plain HTTPS (no WebSocket, no native crypto), they work on
Flutter web without extra setup.

## Test

```bash
dart pub get
dart test         # validation parity + read/write paths (offline, deterministic)
dart analyze
```

## Examples

- [`example/resolve.dart`](example/resolve.dart) — resolve a name
- [`example/register.dart`](example/register.dart) — register via a signer

Run with `dart run example/resolve.dart john`.

## License

[MIT](LICENSE) © Safrochain
