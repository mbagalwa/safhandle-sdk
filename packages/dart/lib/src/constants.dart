// Network presets, mirroring the JS SDK's packages/js/src/constants.ts.
//
// Unlike the JS client (which dials a CometBFT RPC endpoint via CosmJS), the
// Dart read client talks to the chain's REST/LCD gateway
// (`/cosmwasm/wasm/v1/...`), so the pinned endpoints here are REST URLs. Writes
// are delegated to a pluggable signer (see `SafHandleSigner`), so gas/broadcast
// transport is the signer's concern.

import 'package:meta/meta.dart';

/// A network whose contract address is pinned in [contractAddresses].
enum SafHandleNetwork { testnet, mainnet, custom }

/// Network preset. Fill in [contractAddress] with the deployed SafHandle
/// contract's bech32 address (prefix `addr_safro`).
@immutable
class NetworkConfig {
  const NetworkConfig({
    required this.chainId,
    required this.rpcEndpoint,
    required this.restEndpoint,
    required this.addressPrefix,
    required this.denom,
    required this.gasPrice,
    this.contractAddress,
  });

  final String chainId;

  /// CometBFT/Tendermint RPC URL — used by wallet signers, not the read client.
  final String rpcEndpoint;

  /// REST/LCD gateway URL — where [SafHandleClient] issues smart queries.
  final String restEndpoint;

  final String addressPrefix;
  final String denom;
  final String gasPrice;

  /// Deployed SafHandle contract address, or `null` if not pinned here.
  final String? contractAddress;
}

/// Deployed SafHandle contract address per named network, baked into the SDK so
/// callers don't have to carry it around.
const Map<SafHandleNetwork, String> contractAddresses =
    <SafHandleNetwork, String>{
  SafHandleNetwork.testnet:
      'addr_safro17ykz5k26fzg0808knarpgg2tdxxxfmefuh9mydusqyfkr3vtdvysvv2vs0',
  SafHandleNetwork.mainnet:
      'addr_safro14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0nv26n',
};

/// Safrochain testnet (`safro-testnet-1`) preset.
const NetworkConfig safrochainTestnet = NetworkConfig(
  chainId: 'safro-testnet-1',
  rpcEndpoint: 'https://rpc.testnet.safrochain.com',
  restEndpoint: 'https://rest.testnet.safrochain.com',
  addressPrefix: 'addr_safro',
  denom: 'usaf',
  gasPrice: '0.025usaf',
  // SafHandle v1 (name-only) contract on safro-testnet-1.
  contractAddress:
      'addr_safro17ykz5k26fzg0808knarpgg2tdxxxfmefuh9mydusqyfkr3vtdvysvv2vs0',
);

/// Safrochain mainnet (`safrochain-1`) preset.
const NetworkConfig safrochainMainnet = NetworkConfig(
  chainId: 'safrochain-1',
  rpcEndpoint: 'https://rpc.safrochain.network',
  restEndpoint: 'https://api.safrochain.network',
  addressPrefix: 'addr_safro',
  denom: 'usaf',
  gasPrice: '0.15usaf',
  // SafHandle v1 (name-only) contract on safrochain-1.
  contractAddress:
      'addr_safro14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s0nv26n',
);

/// Default gas price used when constructing a signing client.
const String defaultGasPrice = '0.025usaf';

/// Where to point [SafHandleClient.connect]. Choose a named network to reuse its
/// pinned contract address (and default REST endpoint), or `custom` to target
/// any REST endpoint + contract (a local devnet, a fork, or an unlisted
/// deployment).
///
/// Construct one with [ConnectOptions.testnet], [ConnectOptions.mainnet], or
/// [ConnectOptions.custom].
@immutable
class ConnectOptions {
  const ConnectOptions._({
    required this.network,
    required this.restEndpoint,
    required this.contractAddress,
  });

  final SafHandleNetwork network;

  /// REST/LCD gateway URL the read client dials (e.g.
  /// `https://rest.testnet.safrochain.com`, a local node at
  /// `http://localhost:1317`, or a same-origin proxy like `/api/rest`).
  final String restEndpoint;

  /// Resolved contract address for the chosen network.
  final String contractAddress;

  /// Testnet: uses the pinned contract address. [restEndpoint] defaults to the
  /// public testnet gateway but can be overridden (proxy, local node).
  factory ConnectOptions.testnet({String? restEndpoint}) => ConnectOptions._(
        network: SafHandleNetwork.testnet,
        restEndpoint: restEndpoint ?? safrochainTestnet.restEndpoint,
        contractAddress: contractAddresses[SafHandleNetwork.testnet]!,
      );

  /// Mainnet: uses the pinned contract address (currently a placeholder).
  factory ConnectOptions.mainnet({String? restEndpoint}) => ConnectOptions._(
        network: SafHandleNetwork.mainnet,
        restEndpoint: restEndpoint ?? safrochainMainnet.restEndpoint,
        contractAddress: contractAddresses[SafHandleNetwork.mainnet]!,
      );

  /// Custom deployment: you supply both the endpoint and the contract address.
  factory ConnectOptions.custom({
    required String restEndpoint,
    required String contractAddress,
  }) =>
      ConnectOptions._(
        network: SafHandleNetwork.custom,
        restEndpoint: restEndpoint,
        contractAddress: contractAddress,
      );
}
