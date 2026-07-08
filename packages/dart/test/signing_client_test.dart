import 'dart:convert';

import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:safhandle/safhandle.dart';
import 'package:test/test.dart';

// Exercises the write path end-to-end WITHOUT broadcasting: a fake signer
// captures exactly which ExecuteMsg and funds the SDK would submit, and a fake
// HTTP client serves the contract config. Mirrors
// packages/js/test/signing-client.test.ts.

const sender = 'addr_safro1sender';
const contract = 'addr_safro1contract';

const config = <String, dynamic>{
  'native_denom': 'usaf',
  'name_registration_fee_usaf': '50000000',
  'dev_module_wallet': 'addr_safro1dev',
  'governance_admin': 'addr_safro1gov',
  'reserved_names': <String>['safro'],
};

/// Records the last execute call for assertions.
class RecordingSigner implements SafHandleSigner {
  Map<String, dynamic>? lastMsg;
  List<Coin>? lastFunds;
  String? lastContract;
  String? lastMemo;
  int calls = 0;

  @override
  String get sender => 'addr_safro1sender';

  @override
  Future<ExecuteResult> execute({
    required String contract,
    required Map<String, dynamic> msg,
    List<Coin> funds = const <Coin>[],
    String? memo,
  }) async {
    calls++;
    lastContract = contract;
    lastMsg = msg;
    lastFunds = funds;
    lastMemo = memo;
    return const ExecuteResult(transactionHash: 'DEADBEEF', height: 1);
  }
}

/// A fake REST gateway. Counts config queries so tests can assert whether the
/// fee lookup happened.
({http.Client client, int Function() configQueries}) fakeRest() {
  var configQueries = 0;
  final client = MockClient((http.Request request) async {
    // Path: /cosmwasm/wasm/v1/contract/{addr}/smart/{b64}
    final segments = request.url.pathSegments;
    final encoded = segments.last;
    final decoded =
        jsonDecode(utf8.decode(base64.decode(Uri.decodeComponent(encoded))))
            as Map<String, dynamic>;
    if (decoded.containsKey('config')) {
      configQueries++;
      return http.Response(jsonEncode(<String, dynamic>{'data': config}), 200,
          headers: const <String, String>{'content-type': 'application/json'});
    }
    return http.Response('unexpected query', 400);
  });
  return (client: client, configQueries: () => configQueries);
}

SafHandleSigningClient makeClient(
    RecordingSigner signer, http.Client httpClient) {
  return SafHandleSigningClient(
    signer: signer,
    restEndpoint: 'https://rest.example',
    contractAddress: contract,
    httpClient: httpClient,
  );
}

void main() {
  group('registerName', () {
    test('normalizes the name and attaches the exact fee from config',
        () async {
      final signer = RecordingSigner();
      final rest = fakeRest();
      final client = makeClient(signer, rest.client);

      await client.registerName('John');

      expect(rest.configQueries(), 1);
      expect(signer.lastContract, contract);
      expect(signer.lastMsg, <String, dynamic>{
        'register_name': <String, dynamic>{'name': 'john.saf'},
      });
      expect(signer.lastFunds, <Coin>[const Coin('usaf', '50000000')]);
      expect(signer.lastMemo, isNull);
    });

    test('uses an explicit fee override and skips the config query', () async {
      final signer = RecordingSigner();
      final rest = fakeRest();
      final client = makeClient(signer, rest.client);

      await client.registerName(
        'alice',
        options: const WriteOptions(fee: Coin('usaf', '1')),
      );

      expect(rest.configQueries(), 0);
      expect(signer.lastMsg, <String, dynamic>{
        'register_name': <String, dynamic>{'name': 'alice.saf'},
      });
      expect(signer.lastFunds, <Coin>[const Coin('usaf', '1')]);
    });

    test('rejects invalid input before any network or signer call', () async {
      final signer = RecordingSigner();
      final rest = fakeRest();
      final client = makeClient(signer, rest.client);

      await expectLater(
        client.registerName('a'),
        throwsA(isA<SafHandleError>()
            .having((e) => e.code, 'code', SafHandleErrorCode.invalidName)),
      );
      expect(rest.configQueries(), 0);
      expect(signer.calls, 0);
    });
  });

  group('transfer / release (no funds)', () {
    test('transferName sends normalized name and new owner with no funds',
        () async {
      final signer = RecordingSigner();
      final client = makeClient(signer, fakeRest().client);

      await client.transferName('John', 'addr_safro1new');

      expect(signer.lastMsg, <String, dynamic>{
        'transfer_name': <String, dynamic>{
          'name': 'john.saf',
          'new_owner': 'addr_safro1new',
        },
      });
      expect(signer.lastFunds, isEmpty);
    });

    test('releaseName normalizes and sends no funds', () async {
      final signer = RecordingSigner();
      final client = makeClient(signer, fakeRest().client);

      await client.releaseName('John');

      expect(signer.lastMsg, <String, dynamic>{
        'release_name': <String, dynamic>{'name': 'john.saf'},
      });
      expect(signer.lastFunds, isEmpty);
    });
  });

  group('sender', () {
    test("exposes the signer's address", () {
      final client = makeClient(RecordingSigner(), fakeRest().client);
      expect(client.sender, sender);
    });
  });
}
