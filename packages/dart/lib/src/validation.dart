// Client-side mirror of
// safhandle-contract/contracts/safhandle/src/validation.rs (and the JS SDK's
// packages/js/src/validation.ts). Keep in lockstep with the contract: the point
// is to reject bad input and compute the identical `normalizedKey` before
// spending gas.

import 'bech32.dart';
import 'errors.dart';

const String nameSuffix = '.saf';

/// Safrochain bech32 address prefix, shared by testnet and mainnet.
const String addressPrefix = 'addr_safro';

/// Optional display marker for names: `@john` ⇄ canonical `john.saf`.
const String namePrefix = '@';

const int _labelMin = 3;
const int _labelMax = 32;
const int _nameMax = 64;

final RegExp _numericOnly = RegExp(r'^[0-9]+$');
final RegExp _allowedChar = RegExp(r'[a-z0-9-]');

/// True if every code unit in [s] is ASCII (≤ 0x7F).
bool _isAscii(String s) {
  for (final rune in s.runes) {
    if (rune > 0x7f) return false;
  }
  return true;
}

/// Normalize and validate a short name exactly as the contract does:
/// trim → strip a leading `@` display marker → reject email/non-ASCII →
/// lowercase → strip `.saf` suffix → reject stray dots → validate label.
///
/// The leading `@` is a client-side display marker only (`@john` ⇄ `john.saf`);
/// the contract never sees it (the SDK always sends the canonical `john.saf`).
/// Any *other* `@` yields a dedicated [SafHandleErrorCode.emailNotAllowed]
/// error, non-ASCII input is rejected (blocks homoglyph spoofing), and any dot
/// outside the `.saf` suffix is rejected.
///
/// Returns the canonical name, e.g. `john.saf`.
///
/// Throws [SafHandleError] with code `invalidName`, `emailNotAllowed`, or
/// `reservedName`.
String normalizeName(String input) {
  final trimmed = input.trim();
  final bare =
      trimmed.startsWith(namePrefix) ? trimmed.substring(namePrefix.length) : trimmed;
  if (bare.isEmpty) {
    throw const SafHandleError(SafHandleErrorCode.invalidName, 'Name is empty.');
  }

  // Any `@` beyond the leading display marker means an email-shaped input.
  if (bare.contains('@')) {
    throw const SafHandleError(
      SafHandleErrorCode.emailNotAllowed,
      'Email addresses are not valid names.',
    );
  }
  // Reject non-ASCII outright (unicode / homoglyph spoofing).
  if (!_isAscii(bare)) {
    throw const SafHandleError(
      SafHandleErrorCode.invalidName,
      'Names must be ASCII (a–z, 0–9, hyphen).',
    );
  }

  final lowered = bare.toLowerCase();
  final label =
      lowered.endsWith(nameSuffix) ? lowered.substring(0, lowered.length - nameSuffix.length) : lowered;

  // After stripping the single allowed `.saf` suffix, no dot may remain
  // (blocks `john.com`, `a.b.saf`, and other domain/email-shaped input).
  if (label.contains('.')) {
    throw const SafHandleError(
      SafHandleErrorCode.invalidName,
      'Names cannot contain a dot outside the .saf suffix.',
    );
  }

  _validateLabel(label);

  final normalized = '$label$nameSuffix';
  if (normalized.length > _nameMax) {
    throw const SafHandleError(
      SafHandleErrorCode.invalidName,
      'Name exceeds $_nameMax chars.',
    );
  }
  return normalized;
}

void _validateLabel(String label) {
  final len = label.length;
  if (len < _labelMin || len > _labelMax) {
    throw SafHandleError(
      SafHandleErrorCode.invalidName,
      'Name label must be $_labelMin–$_labelMax characters (got $len).',
    );
  }

  // Numeric-only labels are reserved (blocks `123.saf`).
  if (_numericOnly.hasMatch(label)) {
    throw const SafHandleError(
      SafHandleErrorCode.reservedName,
      'Numeric-only names are reserved.',
    );
  }

  for (var i = 0; i < label.length; i++) {
    final ch = label[i];
    if (!_allowedChar.hasMatch(ch)) {
      throw SafHandleError(
        SafHandleErrorCode.invalidName,
        "Illegal character '$ch'. Allowed: a–z, 0–9, hyphen.",
      );
    }
    if (ch == '-' && (i == 0 || i == label.length - 1 || label[i - 1] == '-')) {
      throw const SafHandleError(
        SafHandleErrorCode.invalidName,
        'Hyphens cannot lead, trail, or repeat.',
      );
    }
  }
}

/// True if [value] is a bech32 address carrying the Safrochain prefix. The
/// bech32 checksum is verified, so typos are rejected, not misread as a name.
bool isSafrochainAddress(String value) {
  final decoded = bech32Decode(value.trim());
  return decoded != null && decoded.prefix == addressPrefix;
}

/// Canonical name → display handle, e.g. `john.saf` → `@john`.
String toDisplayName(String normalized) {
  final label = normalized.endsWith(nameSuffix)
      ? normalized.substring(0, normalized.length - nameSuffix.length)
      : normalized;
  return '$namePrefix$label';
}

/// The two kinds of input SafHandle can resolve.
enum HandleKind { name, address }

/// A validated, normalized input together with its detected kind.
class ParsedInput {
  const ParsedInput(this.kind, this.value);

  final HandleKind kind;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is ParsedInput && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'ParsedInput(${kind.name}, $value)';
}

/// Classify and validate a raw input into exactly one lane:
/// - `@handle` → name, normalized to `handle.saf`
/// - anything else → must be a valid Safrochain address
///
/// The two lanes are mutually exclusive (an `@` prefix or a bech32 address), so
/// classification needs no network call. Each lane still fully validates and
/// normalizes its value.
///
/// Throws [SafHandleError] with code `invalidName` | `emailNotAllowed` |
/// `reservedName` when a matched `@name` is malformed, or `invalidInput` when
/// the input is neither an `@name` nor a valid Safrochain address.
ParsedInput parseInput(String raw) {
  final input = raw.trim();
  if (input.startsWith(namePrefix)) {
    return ParsedInput(HandleKind.name, normalizeName(input));
  }
  if (isSafrochainAddress(input)) {
    return ParsedInput(HandleKind.address, input);
  }
  throw const SafHandleError(
    SafHandleErrorCode.invalidInput,
    'Input must be an @name or a Safrochain address.',
  );
}
