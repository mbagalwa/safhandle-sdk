import { SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import type { OfflineSigner } from "@cosmjs/proto-signing";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { SafHandleSigningClient } from "../dist/index.js";

// Exercises the write path end-to-end WITHOUT broadcasting: we stub CosmJS so we
// can assert exactly which ExecuteMsg and funds the SDK would submit.

const SENDER = "addr_safro1sender";
const CONTRACT = "addr_safro1contract";

const CONFIG = {
  native_denom: "usaf",
  name_registration_fee_usaf: "50000000",
  dev_module_wallet: "addr_safro1dev",
  governance_admin: "addr_safro1gov",
  reserved_names: ["safro"],
};

let execute: ReturnType<typeof vi.fn>;
let queryContractSmart: ReturnType<typeof vi.fn>;

async function makeClient(): Promise<SafHandleSigningClient> {
  execute = vi.fn().mockResolvedValue({ transactionHash: "DEADBEEF", height: 1 });
  queryContractSmart = vi.fn().mockResolvedValue(CONFIG);

  const fakeCosmwasm = { execute, queryContractSmart };
  vi.spyOn(SigningCosmWasmClient, "connectWithSigner").mockResolvedValue(
    fakeCosmwasm as unknown as SigningCosmWasmClient,
  );

  const signer = {
    getAccounts: async () => [{ address: SENDER, algo: "secp256k1", pubkey: new Uint8Array() }],
  } as unknown as OfflineSigner;

  return SafHandleSigningClient.connectWithSigner("rpc://x", signer, CONTRACT);
}

beforeEach(async () => {
  // fresh mocks per test via makeClient
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("registerName", () => {
  it("normalizes the name and attaches the exact fee from config", async () => {
    const client = await makeClient();
    await client.registerName("John");

    expect(queryContractSmart).toHaveBeenCalledWith(CONTRACT, { config: {} });
    expect(execute).toHaveBeenCalledWith(
      SENDER,
      CONTRACT,
      { register_name: { name: "john.saf" } },
      "auto",
      undefined,
      [{ denom: "usaf", amount: "50000000" }],
    );
  });

  it("uses an explicit fee override and skips the config query", async () => {
    const client = await makeClient();
    await client.registerName("alice", { fee: { denom: "usaf", amount: "1" } });

    expect(queryContractSmart).not.toHaveBeenCalled();
    expect(execute).toHaveBeenCalledWith(
      SENDER,
      CONTRACT,
      { register_name: { name: "alice.saf" } },
      "auto",
      undefined,
      [{ denom: "usaf", amount: "1" }],
    );
  });

  it("rejects invalid input before any network call", async () => {
    const client = await makeClient();
    await expect(client.registerName("a")).rejects.toMatchObject({ code: "InvalidName" });
    expect(queryContractSmart).not.toHaveBeenCalled();
    expect(execute).not.toHaveBeenCalled();
  });
});

describe("transfer / release (no funds)", () => {
  it("transferName sends normalized name and new owner with no funds", async () => {
    const client = await makeClient();
    await client.transferName("John", "addr_safro1new");

    expect(execute).toHaveBeenCalledWith(
      SENDER,
      CONTRACT,
      { transfer_name: { name: "john.saf", new_owner: "addr_safro1new" } },
      "auto",
      undefined,
      undefined,
    );
  });

  it("releaseName normalizes and sends no funds", async () => {
    const client = await makeClient();
    await client.releaseName("John");

    expect(execute).toHaveBeenCalledWith(
      SENDER,
      CONTRACT,
      { release_name: { name: "john.saf" } },
      "auto",
      undefined,
      undefined,
    );
  });
});

describe("sender", () => {
  it("exposes the signer's first account address", async () => {
    const client = await makeClient();
    expect(client.sender).toBe(SENDER);
  });
});
