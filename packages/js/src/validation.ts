// Client-side mirror of safhandle-contract/contracts/safhandle/src/validation.rs.
// Keep in lockstep with the contract: the point is to reject bad input and
// compute the identical `normalized_key` before spending gas.

import { fromBech32 } from "@cosmjs/encoding";

import { SafHandleError } from "./errors.js";

export const NAME_SUFFIX = ".saf";
/** Safrochain bech32 address prefix, shared by testnet and mainnet. */
export const ADDRESS_PREFIX = "addr_safro";
/** Optional display marker for names: `@john` ⇄ canonical `john.saf`. */
export const NAME_PREFIX = "@";
const LABEL_MIN = 3;
const LABEL_MAX = 32;
const NAME_MAX = 64;

/** True if every code point in `s` is ASCII (≤ 0x7F). */
function isAscii(s: string): boolean {
  for (const ch of s) {
    if (ch.codePointAt(0)! > 0x7f) return false;
  }
  return true;
}

/**
 * Normalize and validate a short name exactly as the contract does:
 * trim → strip a leading `@` display marker → reject email/non-ASCII →
 * lowercase → strip `.saf` suffix → reject stray dots → validate label.
 *
 * The leading `@` is a client-side display marker only (`@john` ⇄ `john.saf`);
 * the contract never sees it (the SDK always sends the canonical `john.saf`).
 * A hardened contract mirror: any *other* `@` yields a dedicated
 * `EmailNotAllowed` error, non-ASCII input is rejected (blocks homoglyph
 * spoofing), and any dot outside the `.saf` suffix is rejected.
 * @returns the canonical name, e.g. `john.saf`.
 * @throws {SafHandleError} `InvalidName`, `EmailNotAllowed`, or `ReservedName`.
 */
export function normalizeName(input: string): string {
  const trimmed = input.trim();
  const bare = trimmed.startsWith(NAME_PREFIX) ? trimmed.slice(NAME_PREFIX.length) : trimmed;
  if (bare.length === 0) {
    throw new SafHandleError("InvalidName", "Name is empty.");
  }

  // Any `@` beyond the leading display marker means an email-shaped input.
  if (bare.includes("@")) {
    throw new SafHandleError("EmailNotAllowed", "Email addresses are not valid names.");
  }
  // Reject non-ASCII outright (unicode / homoglyph spoofing).
  if (!isAscii(bare)) {
    throw new SafHandleError("InvalidName", "Names must be ASCII (a–z, 0–9, hyphen).");
  }

  const lowered = bare.toLowerCase();
  const label = lowered.endsWith(NAME_SUFFIX)
    ? lowered.slice(0, -NAME_SUFFIX.length)
    : lowered;

  // After stripping the single allowed `.saf` suffix, no dot may remain
  // (blocks `john.com`, `a.b.saf`, and other domain/email-shaped input).
  if (label.includes(".")) {
    throw new SafHandleError("InvalidName", "Names cannot contain a dot outside the .saf suffix.");
  }

  validateLabel(label);

  const normalized = `${label}${NAME_SUFFIX}`;
  if (normalized.length > NAME_MAX) {
    throw new SafHandleError("InvalidName", `Name exceeds ${NAME_MAX} chars.`);
  }
  return normalized;
}

function validateLabel(label: string): void {
  const len = label.length;
  if (len < LABEL_MIN || len > LABEL_MAX) {
    throw new SafHandleError(
      "InvalidName",
      `Name label must be ${LABEL_MIN}–${LABEL_MAX} characters (got ${len}).`,
    );
  }

  // Numeric-only labels are reserved (blocks `123.saf`).
  if (/^[0-9]+$/.test(label)) {
    throw new SafHandleError("ReservedName", "Numeric-only names are reserved.");
  }

  for (let i = 0; i < label.length; i++) {
    const ch = label[i]!;
    if (!/[a-z0-9-]/.test(ch)) {
      throw new SafHandleError(
        "InvalidName",
        `Illegal character '${ch}'. Allowed: a–z, 0–9, hyphen.`,
      );
    }
    if (ch === "-" && (i === 0 || i === label.length - 1 || label[i - 1] === "-")) {
      throw new SafHandleError(
        "InvalidName",
        "Hyphens cannot lead, trail, or repeat.",
      );
    }
  }
}

/** True if `value` is a bech32 address carrying the Safrochain prefix. The
 * bech32 checksum is verified, so typos are rejected, not misread as a name. */
export function isSafrochainAddress(value: string): boolean {
  try {
    return fromBech32(value.trim()).prefix === ADDRESS_PREFIX;
  } catch {
    return false;
  }
}

/** Canonical name → display handle, e.g. `john.saf` → `@john`. */
export function toDisplayName(normalized: string): string {
  const label = normalized.endsWith(NAME_SUFFIX)
    ? normalized.slice(0, -NAME_SUFFIX.length)
    : normalized;
  return `${NAME_PREFIX}${label}`;
}

/** The two kinds of input SafHandle can resolve. */
export type HandleKind = "name" | "address";

/** A validated, normalized input together with its detected kind. */
export type ParsedInput =
  | { kind: "name"; value: string }
  | { kind: "address"; value: string };

/**
 * Classify and validate a raw input into exactly one lane:
 * - `@handle` → name, normalized to `handle.saf`
 * - anything else → must be a valid Safrochain address
 *
 * The two lanes are mutually exclusive (an `@` prefix or a bech32 address), so
 * classification needs no network call. Each lane still fully validates and
 * normalizes its value.
 * @throws {SafHandleError} `InvalidName` | `EmailNotAllowed` | `ReservedName`
 *   when a matched `@name` is malformed, or `InvalidInput` when the input is
 *   neither an `@name` nor a valid Safrochain address.
 */
export function parseInput(raw: string): ParsedInput {
  const input = raw.trim();
  if (input.startsWith(NAME_PREFIX)) {
    return { kind: "name", value: normalizeName(input) };
  }
  if (isSafrochainAddress(input)) {
    return { kind: "address", value: input };
  }
  throw new SafHandleError(
    "InvalidInput",
    "Input must be an @name or a Safrochain address.",
  );
}
