import 'dart:convert';

import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:safhandle/safhandle.dart';
import 'package:test/test.dart';

// Drives the read client against a fake REST/LCD gateway: asserts the smart
// query it builds and how it decodes responses, including the notFound path.

const contract = 'addr_safro1contract';

/// Decode the base64 smart-query the client put in the URL path.
Map<String, dynamic> decodeQuery(http.Request request) {
  final encoded = request.url.pathSegments.last;
  return jsonDecode(utf8.decode(base64.decode(Uri.decodeComponent(encoded))))
      as Map<String, dynamic>;
}

SafHandleClient clientWith(MockClient mock) => SafHandleClient(
      restEndpoint: 'https://rest.example',
      contractAddress: contract,
      httpClient: mock,
    );

void main() {
  test('getAddress builds a get_address smart query and parses the response', () async {
    late Map<String, dynamic> seenQuery;
    final mock = MockClient((request) async {
      seenQuery = decodeQuery(request);
      expect(request.url.path, contains('/cosmwasm/wasm/v1/contract/$contract/smart/'));
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'address': 'addr_safro1owner',
            'record_type': 'name',
            'normalized_key': 'john.saf',
          },
        }),
        200,
      );
    });

    final res = await clientWith(mock).getAddress('john');

    expect(seenQuery, <String, dynamic>{
      'get_address': <String, dynamic>{'input': 'john'},
    });
    expect(res.address, 'addr_safro1owner');
    expect(res.recordType, 'name');
    expect(res.normalizedKey, 'john.saf');
  });

  test('lookup returns null when the record is not found', () async {
    final mock = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'code': 3,
          'message': 'query wasm contract failed: name not found',
        }),
        400,
      );
    });

    expect(await clientWith(mock).lookup('ghost'), isNull);
  });

  test('lookup rethrows non-notFound query errors', () async {
    final mock = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{'code': 13, 'message': 'internal error'}),
        500,
      );
    });

    await expectLater(
      clientWith(mock).lookup('john'),
      throwsA(isA<SafHandleQueryException>()),
    );
  });

  test('getHandles parses a null name (address owns nothing)', () async {
    final mock = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{'data': <String, dynamic>{'name': null}}),
        200,
      );
    });

    final res = await clientWith(mock).getHandles('addr_safro1nobody');
    expect(res.name, isNull);
  });

  test('getConfig parses the contract config', () async {
    final mock = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'native_denom': 'usaf',
            'name_registration_fee_usaf': '50000000',
            'dev_module_wallet': 'addr_safro1dev',
            'governance_admin': 'addr_safro1gov',
            'reserved_names': <String>['safro'],
          },
        }),
        200,
      );
    });

    final config = await clientWith(mock).getConfig();
    expect(config.nativeDenom, 'usaf');
    expect(config.nameRegistrationFeeUsaf, '50000000');
    expect(config.reservedNames, <String>['safro']);
  });

  test('connect uses the pinned testnet contract address', () {
    final client = SafHandleClient.connect(ConnectOptions.testnet());
    expect(client.contractAddress, contractAddresses[SafHandleNetwork.testnet]);
    expect(client.restEndpoint, safrochainTestnet.restEndpoint);
  });
}
