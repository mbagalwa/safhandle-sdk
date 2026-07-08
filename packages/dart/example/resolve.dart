// Read-only: resolve a wallet address from a name.
//
// Run: dart run example/resolve.dart john
// Point at a different deployment with SAFHANDLE_CONTRACT.
import 'dart:io';

import 'package:safhandle/safhandle.dart';

Future<void> main(List<String> args) async {
  final input = args.isNotEmpty ? args.first : 'john';

  // Testnet's contract address is baked into the SDK. Set SAFHANDLE_CONTRACT to
  // point at a different deployment via the `custom` network.
  final contract = Platform.environment['SAFHANDLE_CONTRACT'];
  final client = SafHandleClient.connect(
    contract != null
        ? ConnectOptions.custom(
            restEndpoint: safrochainTestnet.restEndpoint,
            contractAddress: contract,
          )
        : ConnectOptions.testnet(),
  );

  try {
    final address = await client.lookup(input);
    if (address == null) {
      stdout.writeln('"$input" is not registered.');
      return;
    }

    final record = await client.getAddress(input);
    stdout.writeln('$input → $address');
    stdout
        .writeln('  type: ${record.recordType}, key: ${record.normalizedKey}');
  } finally {
    client.close();
  }
}
