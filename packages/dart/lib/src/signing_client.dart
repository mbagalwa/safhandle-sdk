import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'client.dart';
import 'constants.dart';
import 'types.dart';
import 'validation.dart';

/// Result of a signed, broadcast execute call.
@immutable
class ExecuteResult {
  const ExecuteResult(
      {required this.transactionHash, this.height, this.rawLog});

  final String transactionHash;
  final int? height;
  final String? rawLog;

  @override
  String toString() => 'ExecuteResult(tx: $transactionHash, height: $height)';
}

/// A pluggable signer + broadcaster. This is the Dart analogue of the
/// `OfflineSigner` + `SigningCosmWasmClient` pair the JS SDK depends on: the
/// SafHandle SDK owns message construction and fee logic, and delegates the
/// actual signing/broadcast of a CosmWasm `MsgExecuteContract` to your Cosmos
/// stack (e.g. a `cosmos_sdk`/`alan`-based signer, or a mobile wallet reached
/// over WalletConnect).
///
/// Implementations must:
/// - expose the [sender] bech32 address (`addr_safro…`), and
/// - sign, broadcast, and await inclusion of a single execute message.
abstract class SafHandleSigner {
  /// The signer's address; sender of every execute call.
  String get sender;

  /// Sign, broadcast, and await a CosmWasm execute against [contract] carrying
  /// the JSON [msg] and optional [funds]/[memo]. Return once the tx is included.
  Future<ExecuteResult> execute({
    required String contract,
    required Map<String, dynamic> msg,
    List<Coin> funds,
    String? memo,
  });
}

/// Per-write options: an explicit fee override and/or a tx memo.
@immutable
class WriteOptions {
  const WriteOptions({this.fee, this.memo});

  /// Exact funds to attach. If omitted, [SafHandleSigningClient.registerName]
  /// fetches the current fee from the contract config so the amount always
  /// matches (the contract requires an exact fee). Provide this to skip the
  /// extra query.
  final Coin? fee;

  /// Optional tx memo.
  final String? memo;
}

/// Read + write SafHandle client. Extends [SafHandleClient] with signed,
/// state-changing calls (register, transfer, release).
///
/// Construction takes a [SafHandleSigner] plus the same REST/contract config as
/// the read client, so all read methods are available here too.
///
/// Port of the JS SDK's [SafHandleSigningClient]; the write surface (normalize
/// locally, attach the exact fee, submit the same `ExecuteMsg`) is identical.
class SafHandleSigningClient extends SafHandleClient {
  SafHandleSigningClient({
    required this.signer,
    required super.restEndpoint,
    required super.contractAddress,
    super.httpClient,
  });

  /// The injected signer that signs and broadcasts every execute call.
  final SafHandleSigner signer;

  /// Connect a signing client from a named-network preset.
  ///
  /// ```dart
  /// final client = SafHandleSigningClient.connect(
  ///   signer: mySigner,
  ///   options: ConnectOptions.testnet(),
  /// );
  /// ```
  factory SafHandleSigningClient.connect({
    required SafHandleSigner signer,
    required ConnectOptions options,
    http.Client? httpClient,
  }) {
    return SafHandleSigningClient(
      signer: signer,
      restEndpoint: options.restEndpoint,
      contractAddress: options.contractAddress,
      httpClient: httpClient,
    );
  }

  /// The signer's address; sender of every execute call.
  String get sender => signer.sender;

  Future<ExecuteResult> _exec(
    Map<String, dynamic> msg, {
    List<Coin> funds = const <Coin>[],
    String? memo,
  }) {
    return signer.execute(
      contract: contractAddress,
      msg: msg,
      funds: funds,
      memo: memo,
    );
  }

  /// Register a short name for the sender. Validates and normalizes locally,
  /// attaches the exact registration fee (from [WriteOptions.fee], else fetched
  /// from the contract config).
  Future<ExecuteResult> registerName(String name,
      {WriteOptions? options}) async {
    final normalized = normalizeName(name);
    final fee = options?.fee ?? await _nameFee();
    return _exec(
      ExecuteMsg.registerName(normalized),
      funds: <Coin>[fee],
      memo: options?.memo,
    );
  }

  /// Transfer name ownership. Owner-only. No funds attached.
  Future<ExecuteResult> transferName(
    String name,
    String newOwner, {
    String? memo,
  }) {
    final normalized = normalizeName(name);
    return _exec(ExecuteMsg.transferName(normalized, newOwner), memo: memo);
  }

  /// Release a name back to the pool. Owner-only. No funds attached.
  Future<ExecuteResult> releaseName(String name, {String? memo}) {
    return _exec(ExecuteMsg.releaseName(normalizeName(name)), memo: memo);
  }

  Future<Coin> _nameFee() async {
    final config = await getConfig();
    return Coin(config.nativeDenom, config.nameRegistrationFeeUsaf);
  }
}
