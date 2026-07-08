import 'package:safhandle/safhandle.dart';
import 'package:test/test.dart';

// Mirrors packages/js/test/validation.test.ts, which in turn mirrors the
// contract's validation.rs tests. If these drift from the contract,
// registrations built by the SDK would be rejected on-chain — so parity matters.

const addr =
    'addr_safro10fmuatrxlcj6644vang5fuwyvdldfjss4tqqvemw9upm0qpn54esxr94v2';

void main() {
  group('normalizeName', () {
    test('normalizes valid names like the contract', () {
      expect(normalizeName('  John  '), 'john.saf');
      expect(normalizeName('alice'), 'alice.saf');
      expect(normalizeName('John.SAF'), 'john.saf');
      expect(normalizeName('my-name'), 'my-name.saf');
    });

    test('is idempotent on already-normalized input', () {
      expect(normalizeName('john.saf'), 'john.saf');
      expect(normalizeName(normalizeName('john')), 'john.saf');
    });

    test("strips a single leading '@' display marker", () {
      expect(normalizeName('@john'), 'john.saf');
      expect(normalizeName('  @John.SAF '), 'john.saf');
      expect(() => normalizeName('@'), throwsA(isA<SafHandleError>()));
      expect(() => normalizeName('@@john'), throwsA(isA<SafHandleError>()));
    });

    test('accepts the length boundaries (3 and 32 chars)', () {
      expect(normalizeName('abc'), 'abc.saf');
      final max = 'a' * 32;
      expect(normalizeName(max), '$max.saf');
    });

    test('rejects malformed names with the right code', () {
      const cases = <(String, SafHandleErrorCode)>[
        ('a', SafHandleErrorCode.invalidName), // too short
        ('ab', SafHandleErrorCode.invalidName), // too short
        ('', SafHandleErrorCode.invalidName), // empty
        ('   ', SafHandleErrorCode.invalidName), // empty after trim
        ('john.safrochain.com', SafHandleErrorCode.invalidName), // illegal '.'
        ('-bad', SafHandleErrorCode.invalidName), // leading hyphen
        ('bad-', SafHandleErrorCode.invalidName), // trailing hyphen
        ('a--b', SafHandleErrorCode.invalidName), // consecutive hyphens
        ('under_score', SafHandleErrorCode.invalidName), // illegal '_'
        ('café', SafHandleErrorCode.invalidName), // non-ascii
        ('123', SafHandleErrorCode.reservedName), // numeric-only
        ('000', SafHandleErrorCode.reservedName), // numeric-only
      ];
      for (final (input, code) in cases) {
        expect(
          () => normalizeName(input),
          throwsA(
            isA<SafHandleError>().having((e) => e.code, 'code', code),
          ),
          reason: 'input: ${input.isEmpty ? '<empty>' : input}',
        );
      }
      // Label too long (33 chars) — separated to build the string.
      expect(
        () => normalizeName('a' * 33),
        throwsA(isA<SafHandleError>()
            .having((e) => e.code, 'code', SafHandleErrorCode.invalidName)),
      );
    });

    test('rejects email-shaped input as emailNotAllowed', () {
      const cases = <String>[
        'john@gmail.com',
        'john@safrochain.com',
        'a@b',
        '  bob@x.saf ',
        '@@john', // second '@' is inside the label
      ];
      for (final input in cases) {
        expect(
          () => normalizeName(input),
          throwsA(isA<SafHandleError>().having(
              (e) => e.code, 'code', SafHandleErrorCode.emailNotAllowed)),
          reason: 'input: $input',
        );
      }
    });
  });

  group('isSafrochainAddress', () {
    test('accepts a valid bech32 address with the safro prefix', () {
      expect(isSafrochainAddress(addr), isTrue);
      expect(isSafrochainAddress(' $addr '), isTrue);
    });

    test('rejects non-addresses and wrong-prefix / bad-checksum inputs', () {
      expect(isSafrochainAddress('john'), isFalse);
      expect(isSafrochainAddress('@john'), isFalse);
      expect(isSafrochainAddress('+243899123456'), isFalse);
      expect(isSafrochainAddress('cosmos1abcdef'), isFalse); // wrong prefix
      expect(isSafrochainAddress('${addr}x'), isFalse); // broken checksum
    });
  });

  group('toDisplayName', () {
    test('renders the canonical name as an @handle', () {
      expect(toDisplayName('john.saf'), '@john');
      expect(toDisplayName('my-name.saf'), '@my-name');
    });
  });

  group('parseInput', () {
    test("routes '@name' to the name lane, normalized", () {
      expect(
          parseInput('@john'), const ParsedInput(HandleKind.name, 'john.saf'));
      expect(parseInput('  @Alice '),
          const ParsedInput(HandleKind.name, 'alice.saf'));
    });

    test('rejects an all-digit input as invalidInput', () {
      for (final input in <String>['243899123456', '123']) {
        expect(
          () => parseInput(input),
          throwsA(isA<SafHandleError>()
              .having((e) => e.code, 'code', SafHandleErrorCode.invalidInput)),
          reason: 'input: $input',
        );
      }
    });

    test('routes an unmarked valid address to the address lane', () {
      expect(parseInput(addr), ParsedInput(HandleKind.address, addr));
    });

    test('propagates @name validation errors', () {
      expect(() => parseInput('@ab'), throwsA(isA<SafHandleError>()));
      expect(() => parseInput('@john@x'), throwsA(isA<SafHandleError>()));
    });

    test('rejects an unmarked non-address as invalidInput', () {
      expect(
        () => parseInput('john'),
        throwsA(isA<SafHandleError>()
            .having((e) => e.code, 'code', SafHandleErrorCode.invalidInput)),
      );
    });
  });

  group('isNotFound', () {
    test('true for a notFound SafHandleError and not-found messages', () {
      expect(
        isNotFound(const SafHandleError(SafHandleErrorCode.notFound, 'x')),
        isTrue,
      );
      expect(isNotFound(Exception('handle not found')), isTrue);
      expect(isNotFound(Exception('Not Found')), isTrue);
    });

    test('false for other SafHandleErrors and unrelated messages', () {
      expect(
        isNotFound(const SafHandleError(SafHandleErrorCode.invalidName, 'x')),
        isFalse,
      );
      expect(isNotFound(Exception('timeout')), isFalse);
    });
  });
}
