import { describe, expect, it } from "vitest";

import {
  isSafrochainAddress,
  normalizeName,
  parseInput,
  SafHandleError,
  toDisplayName,
} from "../dist/index.js";

const ADDR = "addr_safro10fmuatrxlcj6644vang5fuwyvdldfjss4tqqvemw9upm0qpn54esxr94v2";

// Mirrors safhandle-contract/contracts/safhandle/src/validation.rs tests,
// plus boundary cases. If these drift from the contract, registrations built
// by the SDK would be rejected on-chain — so parity matters.

describe("normalizeName", () => {
  it("normalizes valid names like the contract", () => {
    expect(normalizeName("  John  ")).toBe("john.saf");
    expect(normalizeName("alice")).toBe("alice.saf");
    expect(normalizeName("John.SAF")).toBe("john.saf");
    expect(normalizeName("my-name")).toBe("my-name.saf");
  });

  it("is idempotent on already-normalized input", () => {
    expect(normalizeName("john.saf")).toBe("john.saf");
    expect(normalizeName(normalizeName("john"))).toBe("john.saf");
  });

  it("strips a single leading '@' display marker", () => {
    expect(normalizeName("@john")).toBe("john.saf");
    expect(normalizeName("  @John.SAF ")).toBe("john.saf");
    expect(() => normalizeName("@")).toThrow(SafHandleError); // empty label
    expect(() => normalizeName("@@john")).toThrow(SafHandleError); // '@' illegal in label
  });

  it("accepts the length boundaries (3 and 32 chars)", () => {
    expect(normalizeName("abc")).toBe("abc.saf");
    const max = "a".repeat(32);
    expect(normalizeName(max)).toBe(`${max}.saf`);
  });

  it.each([
    ["a", "InvalidName"], // too short
    ["ab", "InvalidName"], // too short
    ["", "InvalidName"], // empty
    ["   ", "InvalidName"], // empty after trim
    ["john.safrochain.com", "InvalidName"], // illegal '.'
    ["-bad", "InvalidName"], // leading hyphen
    ["bad-", "InvalidName"], // trailing hyphen
    ["a--b", "InvalidName"], // consecutive hyphens
    ["under_score", "InvalidName"], // illegal '_'
    ["café", "InvalidName"], // non-ascii
    ["a".repeat(33), "InvalidName"], // label too long
    ["123", "ReservedName"], // numeric-only
    ["000", "ReservedName"], // numeric-only
  ])("rejects %j with code %s", (input, code) => {
    try {
      normalizeName(input);
      throw new Error(`expected ${JSON.stringify(input)} to throw`);
    } catch (err) {
      expect(err).toBeInstanceOf(SafHandleError);
      expect((err as SafHandleError).code).toBe(code);
    }
  });

  // Hardened validation, mirroring the contract's dedicated EmailNotAllowed
  // error. The leading `@` display marker is stripped first, so any *remaining*
  // `@` means an email-shaped input.
  it.each([
    "john@gmail.com",
    "john@safrochain.com",
    "a@b",
    "  bob@x.saf ",
    "@@john", // second '@' is inside the label
  ])("rejects email-shaped %j as EmailNotAllowed", (input) => {
    try {
      normalizeName(input);
      throw new Error(`expected ${JSON.stringify(input)} to throw`);
    } catch (err) {
      expect(err).toBeInstanceOf(SafHandleError);
      expect((err as SafHandleError).code).toBe("EmailNotAllowed");
    }
  });
});

describe("isSafrochainAddress", () => {
  it("accepts a valid bech32 address with the safro prefix", () => {
    expect(isSafrochainAddress(ADDR)).toBe(true);
    expect(isSafrochainAddress(` ${ADDR} `)).toBe(true);
  });

  it("rejects non-addresses and wrong-prefix / bad-checksum inputs", () => {
    expect(isSafrochainAddress("john")).toBe(false);
    expect(isSafrochainAddress("@john")).toBe(false);
    expect(isSafrochainAddress("+243899123456")).toBe(false);
    expect(isSafrochainAddress("cosmos1abcdef")).toBe(false); // wrong prefix
    expect(isSafrochainAddress(`${ADDR}x`)).toBe(false); // broken checksum
  });
});

describe("toDisplayName", () => {
  it("renders the canonical name as an @handle", () => {
    expect(toDisplayName("john.saf")).toBe("@john");
    expect(toDisplayName("my-name.saf")).toBe("@my-name");
  });
});

describe("parseInput", () => {
  it("routes '@name' to the name lane, normalized", () => {
    expect(parseInput("@john")).toEqual({ kind: "name", value: "john.saf" });
    expect(parseInput("  @Alice ")).toEqual({ kind: "name", value: "alice.saf" });
  });

  it("rejects an all-digit input as InvalidInput", () => {
    // An all-digit string is neither an @name nor a valid address.
    for (const input of ["243899123456", "123"]) {
      try {
        parseInput(input);
        throw new Error(`expected ${JSON.stringify(input)} to throw`);
      } catch (err) {
        expect(err).toBeInstanceOf(SafHandleError);
        expect((err as SafHandleError).code).toBe("InvalidInput");
      }
    }
  });

  it("routes an unmarked valid address to the address lane", () => {
    expect(parseInput(ADDR)).toEqual({ kind: "address", value: ADDR });
  });

  it("propagates @name validation errors", () => {
    expect(() => parseInput("@ab")).toThrow(SafHandleError); // name too short
    expect(() => parseInput("@john@x")).toThrow(SafHandleError); // email-shaped label
  });

  it("rejects an unmarked non-address as InvalidInput", () => {
    try {
      parseInput("john"); // no '@', not an address
      throw new Error("expected throw");
    } catch (err) {
      expect(err).toBeInstanceOf(SafHandleError);
      expect((err as SafHandleError).code).toBe("InvalidInput");
    }
  });
});
