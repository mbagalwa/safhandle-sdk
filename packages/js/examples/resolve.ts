// Read-only: resolve a wallet address from a name.
// Run: npx tsx examples/resolve.ts john
import { SAFROCHAIN_TESTNET, SafHandleClient } from "@safrochaindev/safhandle";

async function main() {
  const input = process.argv[2] ?? "john";

  // Testnet's contract address is baked into the SDK. Set SAFHANDLE_CONTRACT to
  // point at a different deployment via the `custom` network.
  const contract = process.env.SAFHANDLE_CONTRACT;
  const client = await SafHandleClient.connect(
    contract
      ? {
          network: "custom",
          rpcEndpoint: SAFROCHAIN_TESTNET.rpcEndpoint,
          contractAddress: contract,
        }
      : { network: "testnet", rpcEndpoint: SAFROCHAIN_TESTNET.rpcEndpoint },
  );

  const address = await client.lookup(input);
  if (address === null) {
    console.log(`"${input}" is not registered.`);
    return;
  }

  const record = await client.getAddress(input);
  console.log(`${input} → ${address}`);
  console.log(`  type: ${record.record_type}, key: ${record.normalized_key}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
