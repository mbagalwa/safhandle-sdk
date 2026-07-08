/** Network presets. Fill in `contractAddress` with the deployed SafHandle
 * contract's bech32 address (prefix `addr_safro`). */
export interface NetworkConfig {
  chainId: string;
  rpcEndpoint: string;
  addressPrefix: string;
  denom: string;
  gasPrice: string;
  /** Deployed SafHandle contract address, or `undefined` if not pinned here. */
  contractAddress?: string;
}

/**
 * Deployed SafHandle contract address per named network, baked into the SDK so
 * callers don't have to carry it around.
 *
 * `mainnet` is a placeholder — swap it for the real address once the contract
 * is deployed and the SDK is verified against it.
 */
export const CONTRACT_ADDRESSES = {
  testnet: "addr_safro17ykz5k26fzg0808knarpgg2tdxxxfmefuh9mydusqyfkr3vtdvysvv2vs0",
  mainnet: "addr_saf_MAIN_NET",
} as const;

/** A network whose contract address is pinned in {@link CONTRACT_ADDRESSES}. */
export type KnownNetwork = keyof typeof CONTRACT_ADDRESSES;

/**
 * Where to point {@link SafHandleClient.connect}. Choose a named network to
 * reuse its pinned contract address, or `"custom"` to target any RPC +
 * contract (a local devnet, a fork, or an unlisted deployment).
 */
export type ConnectOptions =
  | { network: "testnet"; rpcEndpoint: string }
  | { network: "mainnet"; rpcEndpoint: string }
  | { network: "custom"; rpcEndpoint: string; contractAddress: string };

export const SAFROCHAIN_TESTNET: NetworkConfig = {
  chainId: "safro-testnet-1",
  rpcEndpoint: "https://rpc.testnet.safrochain.com",
  addressPrefix: "addr_safro",
  denom: "usaf",
  gasPrice: "0.025usaf",
  // SafHandle v1 (name-only) contract on safro-testnet-1.
  contractAddress: CONTRACT_ADDRESSES.testnet,
};

/** Default gas price used when constructing a signing client. */
export const DEFAULT_GAS_PRICE = "0.025usaf";
