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

export const SAFROCHAIN_TESTNET: NetworkConfig = {
  chainId: "safro-testnet-1",
  rpcEndpoint: "https://rpc.testnet.safrochain.com",
  addressPrefix: "addr_safro",
  denom: "usaf",
  gasPrice: "0.025usaf",
  // SafHandle v1 (name-only) contract on safro-testnet-1, code_id 157.
  // Source of truth: safhandle-contract/config/testnet.json.
  contractAddress: "addr_safro1j6n2q333gy80pmpd6avss32y4nhd8deayv8m9x4uazt6zkdczk9sxjfun6",
};

/** Default gas price used when constructing a signing client. */
export const DEFAULT_GAS_PRICE = "0.025usaf";
