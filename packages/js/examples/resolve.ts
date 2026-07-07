// Read-only: resolve a wallet address from a name.
// Run: npx tsx examples/resolve.ts john
import { SAFROCHAIN_TESTNET, SafHandleClient } from "@safrochain/safhandle";

const CONTRACT_ADDRESS =
  process.env.SAFHANDLE_CONTRACT ?? SAFROCHAIN_TESTNET.contractAddress!;

async function main() {
  const input = process.argv[2] ?? "john";

  const client = await SafHandleClient.connect(
    SAFROCHAIN_TESTNET.rpcEndpoint,
    CONTRACT_ADDRESS,
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
