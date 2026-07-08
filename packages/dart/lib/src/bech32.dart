/// Minimal, dependency-free bech32 decoder (BIP-173) used only to validate
/// Safrochain addresses. It verifies the checksum — so typos are rejected, not
/// misread as a name — and returns the human-readable prefix.
///
/// This mirrors the checksum-verifying behaviour of `@cosmjs/encoding`'s
/// `fromBech32`. Like CosmJS it does not enforce the 90-character BIP-173 length
/// limit, because Cosmos addresses routinely exceed it.
library;

const String _charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
const List<int> _generator = <int>[
  0x3b6a57b2,
  0x26508e6d,
  0x1ea119fa,
  0x3d4233dd,
  0x2a1462b3,
];

/// A successfully decoded bech32 string: its [prefix] (human-readable part) and
/// the 5-bit data words with the 6-word checksum already stripped.
class Bech32Decoded {
  const Bech32Decoded(this.prefix, this.words);

  final String prefix;
  final List<int> words;
}

int _polymod(List<int> values) {
  var chk = 1;
  for (final value in values) {
    final top = chk >> 25;
    chk = ((chk & 0x1ffffff) << 5) ^ value;
    for (var i = 0; i < 5; i++) {
      if (((top >> i) & 1) == 1) chk ^= _generator[i];
    }
  }
  return chk;
}

List<int> _hrpExpand(String hrp) {
  final units = hrp.codeUnits;
  final result = <int>[];
  for (final c in units) {
    result.add(c >> 5);
  }
  result.add(0);
  for (final c in units) {
    result.add(c & 31);
  }
  return result;
}

bool _verifyChecksum(String hrp, List<int> data) {
  return _polymod(<int>[..._hrpExpand(hrp), ...data]) == 1;
}

/// Decode [input], returning `null` if it is not a valid bech32 string (bad
/// checksum, illegal characters, mixed case, or missing separator).
Bech32Decoded? bech32Decode(String input) {
  // Reject mixed case: bech32 is either all-lower or all-upper.
  final hasLower = input != input.toUpperCase();
  final hasUpper = input != input.toLowerCase();
  if (hasLower && hasUpper) return null;

  final str = input.toLowerCase();
  final sep = str.lastIndexOf('1');
  // Need a non-empty prefix and a 6-character checksum after the separator.
  if (sep < 1 || sep + 7 > str.length) return null;

  final hrp = str.substring(0, sep);
  for (final c in hrp.codeUnits) {
    if (c < 33 || c > 126) return null;
  }

  final dataPart = str.substring(sep + 1);
  final words = <int>[];
  for (final ch in dataPart.split('')) {
    final value = _charset.indexOf(ch);
    if (value == -1) return null;
    words.add(value);
  }

  if (!_verifyChecksum(hrp, words)) return null;
  return Bech32Decoded(hrp, words.sublist(0, words.length - 6));
}
