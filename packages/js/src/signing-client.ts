import {
  SigningCosmWasmClient,
  type ExecuteResult,
} from "@cosmjs/cosmwasm-stargate";
import type { OfflineSigner } from "@cosmjs/proto-signing";
import { type Coin, GasPrice } from "@cosmjs/stargate";

import { SafHandleClient } from "./client.js";
import { DEFAULT_GAS_PRICE } from "./constants.js";
import type { ExecuteMsg } from "./types.js";
import { normalizeName } from "./validation.js";

export interface SigningClientOptions {
  /** Gas price string, e.g. `"0.025usaf"`. Defaults to {@link DEFAULT_GAS_PRICE}. */
  gasPrice?: string;
}

export interface WriteOptions {
  /**
   * Exact funds to attach. If omitted, register/link fetch the current fee from
   * the contract config so the amount always matches (the contract requires an
   * exact fee). Provide this to skip the extra query.
   */
  fee?: Coin;
  /** Optional tx memo. */
  memo?: string;
}

/**
 * Read + write SafHandle client. Extends {@link SafHandleClient} with signed,
 * state-changing calls (register, link, transfer, release).
 */
export class SafHandleSigningClient extends SafHandleClient {
  private readonly signing: SigningCosmWasmClient;
  /** The signer's address; sender of every execute call. */
  readonly sender: string;

  private constructor(
    signing: SigningCosmWasmClient,
    contractAddress: string,
    sender: string,
  ) {
    super(signing, contractAddress);
    this.signing = signing;
    this.sender = sender;
  }

  /** Connect a signing client. The signer's first account becomes the sender. */
  static async connectWithSigner(
    rpcEndpoint: string,
    signer: OfflineSigner,
    contractAddress: string,
    options: SigningClientOptions = {},
  ): Promise<SafHandleSigningClient> {
    const gasPrice = GasPrice.fromString(options.gasPrice ?? DEFAULT_GAS_PRICE);
    const signing = await SigningCosmWasmClient.connectWithSigner(
      rpcEndpoint,
      signer,
      { gasPrice },
    );
    const accounts = await signer.getAccounts();
    const first = accounts[0];
    if (!first) throw new Error("Signer exposes no accounts.");
    return new SafHandleSigningClient(signing, contractAddress, first.address);
  }

  private exec(
    msg: ExecuteMsg,
    funds: readonly Coin[] | undefined,
    memo: string | undefined,
  ): Promise<ExecuteResult> {
    return this.signing.execute(
      this.sender,
      this.contractAddress,
      msg,
      "auto",
      memo,
      funds,
    );
  }

  /** Register a short name for the sender. Validates and normalizes locally,
   * attaches the exact registration fee. */
  async registerName(name: string, options: WriteOptions = {}): Promise<ExecuteResult> {
    const normalized = normalizeName(name);
    const fee = options.fee ?? (await this.nameFee());
    return this.exec({ register_name: { name: normalized } }, [fee], options.memo);
  }

  /** Transfer name ownership. Owner-only. */
  transferName(
    name: string,
    newOwner: string,
    options: Pick<WriteOptions, "memo"> = {},
  ): Promise<ExecuteResult> {
    const normalized = normalizeName(name);
    return this.exec(
      { transfer_name: { name: normalized, new_owner: newOwner } },
      undefined,
      options.memo,
    );
  }

  /** Release a name back to the pool. Owner-only. */
  releaseName(name: string, options: Pick<WriteOptions, "memo"> = {}): Promise<ExecuteResult> {
    return this.exec({ release_name: { name: normalizeName(name) } }, undefined, options.memo);
  }

  private async nameFee(): Promise<Coin> {
    const config = await this.getConfig();
    return { denom: config.native_denom, amount: config.name_registration_fee_usaf };
  }
}
