import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'errors.dart';
import 'types.dart';

/// Raised when a smart query fails for a reason other than a missing record
/// (transport error, malformed response, or a contract error that is not a
/// "not found"). Use [isNotFound] to distinguish the missing-record case.
class SafHandleQueryException implements Exception {
  const SafHandleQueryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'SafHandleQueryException'
      '${statusCode != null ? ' [$statusCode]' : ''}: $message';
}

/// Read-only SafHandle client. Issues CosmWasm smart queries against the
/// SafHandle contract over the chain's REST/LCD gateway
/// (`/cosmwasm/wasm/v1/contract/{addr}/smart/{query}`).
///
/// Use `SafHandleSigningClient` for registration and other state-changing calls.
///
/// Port of the JS SDK's [SafHandleClient]; the read surface is identical.
class SafHandleClient {
  SafHandleClient({
    required this.restEndpoint,
    required this.contractAddress,
    http.Client? httpClient,
  })  : _http = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  /// REST/LCD base URL, without a trailing slash.
  final String restEndpoint;

  /// Deployed SafHandle contract address the client queries.
  final String contractAddress;

  final http.Client _http;
  final bool _ownsHttpClient;

  /// Connect a read-only client. Pass a named-network [ConnectOptions] to use
  /// its pinned contract address, or [ConnectOptions.custom] with an explicit
  /// `contractAddress` for any other deployment.
  ///
  /// Unlike the JS `connect`, this is synchronous — REST is stateless, so there
  /// is no connection to open up front.
  ///
  /// ```dart
  /// final client = SafHandleClient.connect(ConnectOptions.testnet());
  /// ```
  factory SafHandleClient.connect(
    ConnectOptions options, {
    http.Client? httpClient,
  }) {
    return SafHandleClient(
      restEndpoint: options.restEndpoint,
      contractAddress: options.contractAddress,
      httpClient: httpClient,
    );
  }

  /// Run a raw smart query and return the decoded `data` payload.
  Future<Object?> _query(Map<String, dynamic> msg) async {
    final query = base64.encode(utf8.encode(jsonEncode(msg)));
    final base = restEndpoint.endsWith('/')
        ? restEndpoint.substring(0, restEndpoint.length - 1)
        : restEndpoint;
    final uri = Uri.parse(
      '$base/cosmwasm/wasm/v1/contract/$contractAddress/smart/'
      '${Uri.encodeComponent(query)}',
    );

    late final http.Response res;
    try {
      res = await _http.get(uri,
          headers: const <String, String>{'Accept': 'application/json'});
    } catch (err) {
      throw SafHandleQueryException('Request failed: $err');
    }

    final body = res.body;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
        throw SafHandleQueryException('Unexpected response shape: $body');
      }
      return decoded['data'];
    }

    // Non-2xx: surface a contract "not found" as a typed SafHandleError so
    // callers (and `lookup`) can branch on it; anything else is a query error.
    final message = _extractErrorMessage(body) ?? 'HTTP ${res.statusCode}';
    if (isNotFound(message)) {
      throw SafHandleError(SafHandleErrorCode.notFound, message);
    }
    throw SafHandleQueryException(message, statusCode: res.statusCode);
  }

  static String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String) return message;
      }
    } catch (_) {
      // Not JSON — fall through.
    }
    return body.isEmpty ? null : body;
  }

  Future<Map<String, dynamic>> _queryObject(Map<String, dynamic> msg) async {
    final data = await _query(msg);
    if (data is! Map<String, dynamic>) {
      throw SafHandleQueryException('Expected an object, got: $data');
    }
    return data;
  }

  /// Resolve a name to an address in one call.
  ///
  /// Throws when the handle is unregistered (see [lookup] for a null-returning
  /// variant).
  Future<GetAddressResponse> getAddress(String input) async {
    return GetAddressResponse.fromJson(
        await _queryObject(QueryMsg.getAddress(input)));
  }

  /// Resolve a name, returning just the address, or `null` if the handle is not
  /// registered. Non-"not found" errors still throw.
  Future<String?> lookup(String input) async {
    try {
      final res = await getAddress(input);
      return res.address;
    } catch (err) {
      if (isNotFound(err)) return null;
      rethrow;
    }
  }

  /// Resolve by name only. [name] may be bare (`john`) or full (`john.saf`).
  Future<String> resolveName(String name) async {
    final res = AddressResponse.fromJson(
        await _queryObject(QueryMsg.resolveName(name)));
    return res.address;
  }

  /// Reverse lookup: the name owned by an address. Never throws on a missing
  /// record — [HandlesResponse.name] comes back as `null` when the address owns
  /// none.
  Future<HandlesResponse> getHandles(String address) async {
    return HandlesResponse.fromJson(
        await _queryObject(QueryMsg.handles(address)));
  }

  /// Full record for a name, including owner and registration height.
  Future<NameRecord> getNameRecord(String name) async {
    return NameRecord.fromJson(await _queryObject(QueryMsg.nameRecord(name)));
  }

  /// Current contract configuration (fees, denom, governance admin).
  Future<Config> getConfig() async {
    return Config.fromJson(await _queryObject(QueryMsg.config()));
  }

  /// Close the underlying HTTP client if this instance created it. No-op when an
  /// external [http.Client] was injected (the caller owns its lifecycle).
  void close() {
    if (_ownsHttpClient) _http.close();
  }
}
