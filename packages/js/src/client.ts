import { CosmWasmClient } from "@cosmjs/cosmwasm-stargate";

import { CONTRACT_ADDRESSES, type ConnectOptions } from "./constants.js";
import { isNotFound } from "./errors.js";
import type {
  AddressResponse,
  Config,
  GetAddressResponse,
  HandlesResponse,
  NameRecord,
  QueryMsg,
} from "./types.js";

/**
 * Read-only SafHandle client. Wraps CosmWasm smart queries against the
 * SafHandle contract. Use {@link SafHandleSigningClient} for registration and
 * other state-changing calls.
 */
export class SafHandleClient {
  protected readonly cosmwasm: CosmWasmClient;
  readonly contractAddress: string;

  constructor(cosmwasm: CosmWasmClient, contractAddress: string) {
    this.cosmwasm = cosmwasm;
    this.contractAddress = contractAddress;
  }

  /**
   * Connect a read-only client. Pass a named network (`"testnet"`/`"mainnet"`)
   * to use its pinned contract address, or `"custom"` with an explicit
   * `contractAddress` for any other deployment.
   *
   * @example
   * await SafHandleClient.connect({
   *   network: "testnet",
   *   rpcEndpoint: SAFROCHAIN_TESTNET.rpcEndpoint,
   * });
   */
  static async connect(options: ConnectOptions): Promise<SafHandleClient> {
    const contractAddress =
      options.network === "custom"
        ? options.contractAddress
        : CONTRACT_ADDRESSES[options.network];
    const cosmwasm = await CosmWasmClient.connect(options.rpcEndpoint);
    return new SafHandleClient(cosmwasm, contractAddress);
  }

  protected query<T>(msg: QueryMsg): Promise<T> {
    return this.cosmwasm.queryContractSmart(this.contractAddress, msg) as Promise<T>;
  }

  /**
   * Resolve a name to an address in one call.
   * @throws when the handle is unregistered (see {@link lookup} for a
   * null-returning variant).
   */
  getAddress(input: string): Promise<GetAddressResponse> {
    return this.query<GetAddressResponse>({ get_address: { input } });
  }

  /**
   * Resolve a name, returning just the address, or `null` if the handle is not
   * registered. Non-"not found" errors still throw.
   */
  async lookup(input: string): Promise<string | null> {
    try {
      const res = await this.getAddress(input);
      return res.address;
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  }

  /** Resolve by name only. `name` may be bare (`john`) or full (`john.saf`). */
  async resolveName(name: string): Promise<string> {
    const res = await this.query<AddressResponse>({ resolve_name: { name } });
    return res.address;
  }

  /** Reverse lookup: the name owned by an address. Never throws on a missing
   * record — `name` comes back as `null` when the address owns none. */
  getHandles(address: string): Promise<HandlesResponse> {
    return this.query<HandlesResponse>({ handles: { address } });
  }

  /** Full record for a name, including owner and registration height. */
  getNameRecord(name: string): Promise<NameRecord> {
    return this.query<NameRecord>({ name_record: { name } });
  }

  /** Current contract configuration (fees, denom, governance admin). */
  getConfig(): Promise<Config> {
    return this.query<Config>({ config: {} });
  }
}
