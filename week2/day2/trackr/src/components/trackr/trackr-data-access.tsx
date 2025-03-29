'use client'

import { getTrackrProgram, getTrackrProgramId } from '@project/anchor'
import { useConnection } from '@solana/wallet-adapter-react'
import { Cluster, Keypair, PublicKey } from '@solana/web3.js'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useMemo } from 'react'
import toast from 'react-hot-toast'
import { useCluster } from '../cluster/cluster-data-access'
import { useAnchorProvider } from '../solana/solana-provider'
import { useTransactionToast } from '../ui/ui-layout'

export function useTrackrProgram() {
  const { connection } = useConnection()
  const { cluster } = useCluster()
  const transactionToast = useTransactionToast()
  const provider = useAnchorProvider()
  const programId = useMemo(() => getTrackrProgramId(cluster.network as Cluster), [cluster])
  const program = useMemo(() => getTrackrProgram(provider, programId), [provider, programId])

  const accounts = useQuery({
    queryKey: ['trackr', 'all', { cluster }],
    queryFn: () => program.account.trackr.all(),
  })

  const getProgramAccount = useQuery({
    queryKey: ['get-program-account', { cluster }],
    queryFn: () => connection.getParsedAccountInfo(programId),
  })

  const initialize = useMutation({
    mutationKey: ['trackr', 'initialize', { cluster }],
    mutationFn: (keypair: Keypair) =>
      program.methods.initialize().accounts({ trackr: keypair.publicKey }).signers([keypair]).rpc(),
    onSuccess: (signature) => {
      transactionToast(signature)
      return accounts.refetch()
    },
    onError: () => toast.error('Failed to initialize account'),
  })

  return {
    program,
    programId,
    accounts,
    getProgramAccount,
    initialize,
  }
}

export function useTrackrProgramAccount({ account }: { account: PublicKey }) {
  const { cluster } = useCluster()
  const transactionToast = useTransactionToast()
  const { program, accounts } = useTrackrProgram()

  const accountQuery = useQuery({
    queryKey: ['trackr', 'fetch', { cluster, account }],
    queryFn: () => program.account.trackr.fetch(account),
  })

  const closeMutation = useMutation({
    mutationKey: ['trackr', 'close', { cluster, account }],
    mutationFn: () => program.methods.close().accounts({ trackr: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accounts.refetch()
    },
  })

  const decrementMutation = useMutation({
    mutationKey: ['trackr', 'decrement', { cluster, account }],
    mutationFn: () => program.methods.decrement().accounts({ trackr: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  const incrementMutation = useMutation({
    mutationKey: ['trackr', 'increment', { cluster, account }],
    mutationFn: () => program.methods.increment().accounts({ trackr: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  const setMutation = useMutation({
    mutationKey: ['trackr', 'set', { cluster, account }],
    mutationFn: (value: number) => program.methods.set(value).accounts({ trackr: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  return {
    accountQuery,
    closeMutation,
    decrementMutation,
    incrementMutation,
    setMutation,
  }
}
