import * as anchor from '@coral-xyz/anchor'
import { Program } from '@coral-xyz/anchor'
import { Keypair } from '@solana/web3.js'
import { Trackr } from '../target/types/trackr'

describe('trackr', () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env()
  anchor.setProvider(provider)
  const payer = provider.wallet as anchor.Wallet

  const program = anchor.workspace.Trackr as Program<Trackr>

  const trackrKeypair = Keypair.generate()

  it('Initialize Trackr', async () => {
    await program.methods
      .initialize()
      .accounts({
        trackr: trackrKeypair.publicKey,
        payer: payer.publicKey,
      })
      .signers([trackrKeypair])
      .rpc()

    const currentCount = await program.account.trackr.fetch(trackrKeypair.publicKey)

    expect(currentCount.count).toEqual(0)
  })

  it('Increment Trackr', async () => {
    await program.methods.increment().accounts({ trackr: trackrKeypair.publicKey }).rpc()

    const currentCount = await program.account.trackr.fetch(trackrKeypair.publicKey)

    expect(currentCount.count).toEqual(1)
  })

  it('Increment Trackr Again', async () => {
    await program.methods.increment().accounts({ trackr: trackrKeypair.publicKey }).rpc()

    const currentCount = await program.account.trackr.fetch(trackrKeypair.publicKey)

    expect(currentCount.count).toEqual(2)
  })

  it('Decrement Trackr', async () => {
    await program.methods.decrement().accounts({ trackr: trackrKeypair.publicKey }).rpc()

    const currentCount = await program.account.trackr.fetch(trackrKeypair.publicKey)

    expect(currentCount.count).toEqual(1)
  })

  it('Set trackr value', async () => {
    await program.methods.set(42).accounts({ trackr: trackrKeypair.publicKey }).rpc()

    const currentCount = await program.account.trackr.fetch(trackrKeypair.publicKey)

    expect(currentCount.count).toEqual(42)
  })

  it('Set close the trackr account', async () => {
    await program.methods
      .close()
      .accounts({
        payer: payer.publicKey,
        trackr: trackrKeypair.publicKey,
      })
      .rpc()

    // The account should no longer exist, returning null.
    const userAccount = await program.account.trackr.fetchNullable(trackrKeypair.publicKey)
    expect(userAccount).toBeNull()
  })
})
