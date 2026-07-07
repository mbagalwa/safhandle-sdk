/** Error codes that mirror the contract's `ContractError` variants plus the
 * client-side validation failures raised before a message is sent. */
export type SafHandleErrorCode =
  | "InvalidName"
  | "EmailNotAllowed"
  | "ReservedName"
  | "InvalidInput"
  | "NotFound";

/** A validation or lookup error raised by the SDK. Wrap chain/transport errors
 * from CosmJS as-is; this type is only for SafHandle-domain failures. */
export class SafHandleError extends Error {
  readonly code: SafHandleErrorCode;

  constructor(code: SafHandleErrorCode, message: string) {
    super(message);
    this.name = "SafHandleError";
    this.code = code;
    // Restore prototype chain for instanceof across transpile targets.
    Object.setPrototypeOf(this, SafHandleError.prototype);
  }
}

/** Heuristic: did a CosmJS query fail because the record does not exist?
 * The contract's forward resolvers return `NotFound` for missing handles. */
export function isNotFound(err: unknown): boolean {
  if (err instanceof SafHandleError) return err.code === "NotFound";
  const message = err instanceof Error ? err.message : String(err);
  return /not\s*found/i.test(message);
}
