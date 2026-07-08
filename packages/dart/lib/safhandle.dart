/// Dart/Flutter SDK for the SafHandle name service on Safrochain.
///
/// Resolve a wallet address from a name and register handles on-chain, with
/// client-side validation that mirrors the contract so bad input is rejected
/// before it costs gas.
///
/// This is a faithful port of the TypeScript SDK (`@safrochaindev/safhandle`):
/// - [SafHandleClient] — read-only smart queries over the REST/LCD gateway.
/// - [SafHandleSigningClient] — register/transfer/release via a pluggable
///   [SafHandleSigner].
/// - Validation helpers ([normalizeName], [parseInput], [isSafrochainAddress]…)
///   that mirror the on-chain `validation.rs`.
library;

export 'src/client.dart' show SafHandleClient, SafHandleQueryException;
export 'src/signing_client.dart'
    show SafHandleSigningClient, SafHandleSigner, ExecuteResult, WriteOptions;

export 'src/errors.dart' show SafHandleError, SafHandleErrorCode, isNotFound;

export 'src/validation.dart'
    show
        addressPrefix,
        namePrefix,
        nameSuffix,
        isSafrochainAddress,
        normalizeName,
        parseInput,
        toDisplayName,
        HandleKind,
        ParsedInput;

export 'src/constants.dart'
    show
        ConnectOptions,
        NetworkConfig,
        SafHandleNetwork,
        contractAddresses,
        defaultGasPrice,
        safrochainMainnet,
        safrochainTestnet;

export 'src/types.dart'
    show
        AddressResponse,
        Coin,
        Config,
        ExecuteMsg,
        GetAddressResponse,
        HandlesResponse,
        NameRecord,
        QueryMsg,
        recordTypeName;
