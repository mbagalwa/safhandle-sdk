export { SafHandleClient } from "./client.js";
export {
  SafHandleSigningClient,
  type SigningClientOptions,
  type WriteOptions,
} from "./signing-client.js";

export { SafHandleError, isNotFound, type SafHandleErrorCode } from "./errors.js";
export {
  ADDRESS_PREFIX,
  NAME_PREFIX,
  NAME_SUFFIX,
  isSafrochainAddress,
  normalizeName,
  parseInput,
  toDisplayName,
  type HandleKind,
  type ParsedInput,
} from "./validation.js";
export {
  CONTRACT_ADDRESSES,
  DEFAULT_GAS_PRICE,
  SAFROCHAIN_TESTNET,
  type ConnectOptions,
  type KnownNetwork,
  type NetworkConfig,
} from "./constants.js";

export type {
  AddressResponse,
  Config,
  ExecuteMsg,
  GetAddressResponse,
  HandlesResponse,
  NameRecord,
  QueryMsg,
  RecordType,
} from "./types.js";
