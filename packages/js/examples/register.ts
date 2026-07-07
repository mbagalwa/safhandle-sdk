// Write: register a name from a mnemonic. Needs a funded testnet account.
// Run: SAFHANDLE_MNEMONIC="..." npx tsx examples/register.ts my-name
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";
import { SAFROCHAIN_TESTNET, SafHandleSigningClient } from "@safrochain/safhandle";

const CONTRACT_ADDRESS =
  process.env.SAFHANDLE_CONTRACT ?? SAFROCHAIN_TESTNET.contractAddress!;

async function main() {
  const name = process.argv[2] ?? "my-name";
  const mnemonic = process.env.SAFHANDLE_MNEMONIC;
  if (!mnemonic) throw new Error("Set SAFHANDLE_MNEMONIC to a funded testnet account.");

  const signer = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
    prefix: SAFROCHAIN_TESTNET.addressPrefix,
  });

  const client = await SafHandleSigningClient.connectWithSigner(
    SAFROCHAIN_TESTNET.rpcEndpoint,
    signer,
    CONTRACT_ADDRESS,
    { gasPrice: SAFROCHAIN_TESTNET.gasPrice },
  );

  // Fee is fetched from the contract config automatically.
  const result = await client.registerName(name);
  console.log(`Registered ${name} for ${client.sender}`);
  console.log(`  tx: ${result.transactionHash}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
