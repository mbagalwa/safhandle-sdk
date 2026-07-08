import { describe, expect, it } from "vitest";

import { SafHandleClient, SAFROCHAIN_TESTNET } from "../dist/index.js";

// Live reads against safro-testnet-1. Skipped unless SAFHANDLE_INTEGRATION is
// set, so the default `npm test` stays offline and deterministic.
//   Run with: npm run test:integration
const RUN = !!process.env.SAFHANDLE_INTEGRATION;

// "momo" is registered on testnet by the deploy account (see safhandle-contract/.info).
const KNOWN_NAME = "momo";
const KNOWN_OWNER = "addr_safro1qyzdpg5v9xepwn0jx65uxhjrq07t8v8w93qq7d";

describe.skipIf(!RUN)("integration: live testnet reads", () => {
  async function connect() {
    return SafHandleClient.connect({
      network: "testnet",
      rpcEndpoint: SAFROCHAIN_TESTNET.rpcEndpoint,
    });
  }

  it("getConfig returns the expected fee shape", async () => {
    const client = await connect();
    const config = await client.getConfig();
    expect(config.native_denom).toBe("usaf");
    expect(config.name_registration_fee_usaf).toMatch(/^\d+$/);
    expect(Array.isArray(config.reserved_names)).toBe(true);
  }, 20000);

  it("getAddress resolves a known name", async () => {
    const client = await connect();
    const res = await client.getAddress(KNOWN_NAME);
    expect(res.record_type).toBe("name");
    expect(res.normalized_key).toBe("momo.saf");
    expect(res.address).toBe(KNOWN_OWNER);
  }, 20000);

  it("lookup returns null for an unregistered handle", async () => {
    const client = await connect();
    expect(await client.lookup("definitely-not-registered-zzz")).toBeNull();
  }, 20000);

  it("resolveName returns just the address", async () => {
    const client = await connect();
    expect(await client.resolveName(KNOWN_NAME)).toBe(KNOWN_OWNER);
  }, 20000);

  it("getHandles reverse-resolves the owner to the name", async () => {
    const client = await connect();
    const handles = await client.getHandles(KNOWN_OWNER);
    expect(handles.name).toBe("momo.saf");
  }, 20000);

  it("getNameRecord deserializes the full record", async () => {
    const client = await connect();
    const record = await client.getNameRecord(KNOWN_NAME);
    expect(record.owner).toBe(KNOWN_OWNER);
    expect(Number.isSafeInteger(record.registered_at_height)).toBe(true);
    expect(Number.isSafeInteger(record.registered_at_time)).toBe(true);
  }, 20000);
});
