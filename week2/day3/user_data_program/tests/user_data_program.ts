import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { UserDataProgram } from "../target/types/user_data_program";
import { SystemProgram, Keypair } from "@solana/web3.js";

describe("user_data_program", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.UserDataProgram as Program<UserDataProgram>;
  const userAccount = Keypair.generate();

  it("Initializes user data", async () => {
    const tx = await program.methods
      .initialize("Alice", 25)
      .accounts({
        userAccount: userAccount.publicKey,
        user: provider.wallet.publicKey,
        systemProgram: new anchor.web3.PublicKey("11111111111111111111111111111111"), // Manually define systemProgram
      })
      .signers([userAccount])
      .rpc();

    console.log("Transaction Signature:", tx);

    // Fetch the account data
    const account = await program.account.userData.fetch(userAccount.publicKey);
    console.log("Stored Data:", account);
  });
});
