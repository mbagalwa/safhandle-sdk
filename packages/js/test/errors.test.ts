import { describe, expect, it } from "vitest";

import { isNotFound, SafHandleError } from "../dist/index.js";

describe("SafHandleError", () => {
  it("is an Error with a code and stable name", () => {
    const err = new SafHandleError("InvalidName", "bad");
    expect(err).toBeInstanceOf(Error);
    expect(err).toBeInstanceOf(SafHandleError);
    expect(err.name).toBe("SafHandleError");
    expect(err.code).toBe("InvalidName");
    expect(err.message).toBe("bad");
  });
});

describe("isNotFound", () => {
  it("is true for a NotFound SafHandleError", () => {
    expect(isNotFound(new SafHandleError("NotFound", "x"))).toBe(true);
  });

  it("is false for other SafHandleError codes", () => {
    expect(isNotFound(new SafHandleError("InvalidName", "x"))).toBe(false);
  });

  it("matches the contract's 'Record not found' query error", () => {
    // The exact message CosmJS surfaces from the contract.
    const cosmjsErr = new Error(
      "Query failed with (6): Generic error: Record not found: query wasm contract failed",
    );
    expect(isNotFound(cosmjsErr)).toBe(true);
  });

  it("is false for unrelated errors", () => {
    expect(isNotFound(new Error("connection refused"))).toBe(false);
    expect(isNotFound("some string")).toBe(false);
    expect(isNotFound(undefined)).toBe(false);
  });
});
