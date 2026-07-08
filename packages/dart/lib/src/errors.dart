/// Error codes that mirror the contract's `ContractError` variants plus the
/// client-side validation failures raised before a message is sent.
///
/// Port of `packages/js/src/errors.ts` (`SafHandleErrorCode`).
enum SafHandleErrorCode {
  invalidName,
  emailNotAllowed,
  reservedName,
  invalidInput,
  notFound,
}

/// A validation or lookup error raised by the SDK. Wrap chain/transport errors
/// from the signer/HTTP layer as-is; this type is only for SafHandle-domain
/// failures.
class SafHandleError implements Exception {
  const SafHandleError(this.code, this.message);

  final SafHandleErrorCode code;
  final String message;

  @override
  String toString() => 'SafHandleError(${code.name}): $message';
}

/// Heuristic: did a query fail because the record does not exist?
///
/// The contract's forward resolvers return `NotFound` for missing handles. A
/// [SafHandleError] is checked by [SafHandleError.code]; any other error is
/// matched against its message (mirrors the JS `isNotFound`).
bool isNotFound(Object? err) {
  if (err == null) return false;
  if (err is SafHandleError) return err.code == SafHandleErrorCode.notFound;
  return RegExp(r'not\s*found', caseSensitive: false).hasMatch(err.toString());
}
