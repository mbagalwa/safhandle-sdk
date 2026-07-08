// Write: register a name. The SDK owns message construction, local validation,
// and the exact fee; it delegates signing + broadcast to a SafHandleSigner you
// provide (see README → "Writing: bring your own signer").
//
// This example uses a placeholder signer so it stays dependency-free. Swap
// `_UnimplementedSigner` for one backed by your Cosmos stack (e.g. cosmos_sdk /
// alan) or a mobile wallet over WalletConnect.
//
// Run (once you have wired a real signer):
//   dart run example/register.dart my-name
import 'dart:io';

import 'package:safhandle/safhandle.dart';

Future<void> main(List<String> args) async {
  final name = args.isNotEmpty ? args.first : 'my-name';

  final SafHandleSigner signer = _UnimplementedSigner();

  final client = SafHandleSigningClient.connect(
    signer: signer,
    options: ConnectOptions.testnet(),
  );

  try {
    // Fee is fetched from the contract config automatically.
    final result = await client.registerName(name);
    stdout.writeln('Registered $name for ${client.sender}');
    stdout.writeln('  tx: ${result.transactionHash}');
  } finally {
    client.close();
  }
}

/// Placeholder — replace with a real signer. See the README for how to build one
/// on top of a Cosmos Dart signing library.
class _UnimplementedSigner implements SafHandleSigner {
  @override
  String get sender => 'addr_safro1...';

  @override
  Future<ExecuteResult> execute({
    required String contract,
    required Map<String, dynamic> msg,
    List<Coin> funds = const <Coin>[],
    String? memo,
  }) {
    throw UnimplementedError(
      'Wire a real SafHandleSigner: sign a MsgExecuteContract for $contract '
      'with msg=$msg and funds=$funds, broadcast it, and return the tx hash.',
    );
  }
}
