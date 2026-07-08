// Wire types mirrored from the SafHandle contract schema
// (safhandle-contract/schema/raw/*.json), matching the JS SDK's
// packages/js/src/types.ts. Kept in sync by hand; the JSON Schema is the source
// of truth.

import 'package:meta/meta.dart';

/// A resolved handle is always a `name` in v1.
const String recordTypeName = 'name';

// ── Query responses ──────────────────────────────────────────────────────────

/// Response of `get_address` — resolves a name in one call.
@immutable
class GetAddressResponse {
  const GetAddressResponse({
    required this.address,
    required this.recordType,
    required this.normalizedKey,
  });

  final String address;

  /// Always `"name"` in v1. Typed as a plain string to stay forward-compatible.
  final String recordType;

  /// Canonical key the contract stored, e.g. `john.saf`.
  final String normalizedKey;

  factory GetAddressResponse.fromJson(Map<String, dynamic> json) {
    return GetAddressResponse(
      address: json['address'] as String,
      recordType: json['record_type'] as String,
      normalizedKey: json['normalized_key'] as String,
    );
  }

  @override
  String toString() =>
      'GetAddressResponse(address: $address, recordType: $recordType, normalizedKey: $normalizedKey)';
}

/// Response of `resolve_name`.
@immutable
class AddressResponse {
  const AddressResponse({required this.address});

  final String address;

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      AddressResponse(address: json['address'] as String);
}

/// Reverse-lookup result. [name] is `null` when the address owns no name.
@immutable
class HandlesResponse {
  const HandlesResponse({required this.name});

  final String? name;

  factory HandlesResponse.fromJson(Map<String, dynamic> json) =>
      HandlesResponse(name: json['name'] as String?);

  @override
  String toString() => 'HandlesResponse(name: $name)';
}

/// Contract configuration. `Uint128` fields serialize as decimal strings.
@immutable
class Config {
  const Config({
    required this.nativeDenom,
    required this.nameRegistrationFeeUsaf,
    required this.devModuleWallet,
    required this.governanceAdmin,
    required this.reservedNames,
  });

  final String nativeDenom;
  final String nameRegistrationFeeUsaf;
  final String devModuleWallet;
  final String governanceAdmin;
  final List<String> reservedNames;

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      nativeDenom: json['native_denom'] as String,
      nameRegistrationFeeUsaf: json['name_registration_fee_usaf'] as String,
      devModuleWallet: json['dev_module_wallet'] as String,
      governanceAdmin: json['governance_admin'] as String,
      reservedNames: (json['reserved_names'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .toList(growable: false),
    );
  }
}

/// Full record for a registered name.
@immutable
class NameRecord {
  const NameRecord({
    required this.owner,
    required this.registeredAtHeight,
    required this.registeredAtTime,
  });

  final String owner;
  final int registeredAtHeight;
  final int registeredAtTime;

  factory NameRecord.fromJson(Map<String, dynamic> json) {
    return NameRecord(
      owner: json['owner'] as String,
      registeredAtHeight: (json['registered_at_height'] as num).toInt(),
      registeredAtTime: (json['registered_at_time'] as num).toInt(),
    );
  }
}

/// A native coin amount to attach as funds, e.g. `Coin('usaf', '50000000')`.
@immutable
class Coin {
  const Coin(this.denom, this.amount);

  final String denom;
  final String amount;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'denom': denom, 'amount': amount};

  @override
  bool operator ==(Object other) =>
      other is Coin && other.denom == denom && other.amount == amount;

  @override
  int get hashCode => Object.hash(denom, amount);

  @override
  String toString() => 'Coin($amount$denom)';
}

// ── Message shapes ───────────────────────────────────────────────────────────

/// Builders for the contract's `QueryMsg` variants (JSON maps).
abstract final class QueryMsg {
  static Map<String, dynamic> getAddress(String input) => <String, dynamic>{
        'get_address': <String, dynamic>{'input': input},
      };

  static Map<String, dynamic> resolveName(String name) => <String, dynamic>{
        'resolve_name': <String, dynamic>{'name': name},
      };

  static Map<String, dynamic> config() => <String, dynamic>{
        'config': <String, dynamic>{},
      };

  static Map<String, dynamic> nameRecord(String name) => <String, dynamic>{
        'name_record': <String, dynamic>{'name': name},
      };

  static Map<String, dynamic> handles(String address) => <String, dynamic>{
        'handles': <String, dynamic>{'address': address},
      };
}

/// Builders for the contract's `ExecuteMsg` variants (JSON maps).
abstract final class ExecuteMsg {
  static Map<String, dynamic> registerName(String name) => <String, dynamic>{
        'register_name': <String, dynamic>{'name': name},
      };

  static Map<String, dynamic> transferName(String name, String newOwner) =>
      <String, dynamic>{
        'transfer_name': <String, dynamic>{'name': name, 'new_owner': newOwner},
      };

  static Map<String, dynamic> releaseName(String name) => <String, dynamic>{
        'release_name': <String, dynamic>{'name': name},
      };
}
