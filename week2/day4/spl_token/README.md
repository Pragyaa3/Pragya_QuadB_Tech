# My Custom SPL Token on Solana

## Token Details:
- **Mint Address:** `GS8y7fYbwBJM5YgfMFRKDCdfJBDoQ9nWTZGS1447owqq`
- **Network:** Devnet
- **Supply:** 200 Tokens

## Commands Used:
```sh
solana config set --url https://api.devnet.solana.com
solana config set --keypair ~/.config/solana/id.json
solana airdrop 2
spl-token create-token
spl-token create-account <TOKEN_MINT_ADDRESS>
spl-token mint <TOKEN_MINT_ADDRESS> 200
spl-token balance <TOKEN_MINT_ADDRESS>
spl-token supply <TOKEN_MINT_ADDRESS>
