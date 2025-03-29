// Here we export some useful types and functions for interacting with the Anchor program.
import { AnchorProvider, Program } from '@coral-xyz/anchor'
import { Cluster, PublicKey } from '@solana/web3.js'
import TrackrIDL from '../target/idl/trackr.json'
import type { Trackr } from '../target/types/trackr'

// Re-export the generated IDL and type
export { Trackr, TrackrIDL }

// The programId is imported from the program IDL.
export const TRACKR_PROGRAM_ID = new PublicKey(TrackrIDL.address)

// This is a helper function to get the Trackr Anchor program.
export function getTrackrProgram(provider: AnchorProvider, address?: PublicKey) {
  return new Program({ ...TrackrIDL, address: address ? address.toBase58() : TrackrIDL.address } as Trackr, provider)
}

// This is a helper function to get the program ID for the Trackr program depending on the cluster.
export function getTrackrProgramId(cluster: Cluster) {
  switch (cluster) {
    case 'devnet':
    case 'testnet':
      // This is the program ID for the Trackr program on devnet and testnet.
      return new PublicKey('coUnmi3oBUtwtd9fjeAvSsJssXh5A5xyPbhpewyzRVF')
    case 'mainnet-beta':
    default:
      return TRACKR_PROGRAM_ID
  }
}
