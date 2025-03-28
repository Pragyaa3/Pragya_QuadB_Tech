import * as anchor from "@coral-xyz/anchor";

describe("solana_test", () => {
  anchor.setProvider(anchor.AnchorProvider.env());

  it("Says Hello!", async () => {
    const program = anchor.workspace.SolanaTest;
    const tx = await program.methods.sayHello().rpc();
    console.log("Transaction Signature:", tx);
  });
});
