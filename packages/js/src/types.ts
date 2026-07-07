// Wire types mirrored from the SafHandle contract schema
// (safhandle-contract/schema/raw/*.json). Kept in sync by hand; the JSON Schema
// is the source of truth.

/** A resolved handle is always a `name` in v1. */
export type RecordType = "name";

// ── Query responses ──────────────────────────────────────────────────────────

/** Response of `get_address` — resolves a name in one call. */
export interface GetAddressResponse {
  address: string;
  /** Always `"name"` in v1. Typed loosely to stay forward-compatible. */
  record_type: RecordType | string;
  /** Canonical key the contract stored, e.g. `john.saf`. */
  normalized_key: string;
}

/** Response of `resolve_name`. */
export interface AddressResponse {
  address: string;
}

/** Reverse-lookup result. `name` is `null` when the address owns no name. */
export interface HandlesResponse {
  name: string | null;
}

/** Contract configuration. `Uint128` fields serialize as decimal strings. */
export interface Config {
  native_denom: string;
  name_registration_fee_usaf: string;
  dev_module_wallet: string;
  governance_admin: string;
  reserved_names: string[];
}

/** Full record for a registered name. */
export interface NameRecord {
  owner: string;
  registered_at_height: number;
  registered_at_time: number;
}

// ── Message shapes ───────────────────────────────────────────────────────────

export type QueryMsg =
  | { get_address: { input: string } }
  | { resolve_name: { name: string } }
  | { config: Record<string, never> }
  | { name_record: { name: string } }
  | { handles: { address: string } };

export type ExecuteMsg =
  | { register_name: { name: string } }
  | { transfer_name: { name: string; new_owner: string } }
  | { release_name: { name: string } };
