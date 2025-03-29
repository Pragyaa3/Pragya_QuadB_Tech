# Trackr

Trackr is a Solana-based decentralized application (dApp) built using `create-solana-dapp`. It allows users to connect their Phantom wallet and interact with a Solana program to increment, decrement, and track transaction history.

## Features

- 📈 **Increment & Decrement**: Update on-chain values via Solana transactions.
- 📜 **Transaction History**: View past interactions with the program.
- 🔐 **Wallet Integration**: Connect and interact with the dApp using Phantom Wallet.

## Prerequisites

Ensure you have the following installed:

- [Node.js](https://nodejs.org/) (LTS recommended)
- [Yarn](https://yarnpkg.com/) or npm
- [Solana CLI](https://docs.solana.com/cli/install-solana-cli) (Ensure your local network is set up)

## Cloning & Setup

To get started, follow these steps:

```sh
# Clone the repository
git clone https://github.com/YOUR_GITHUB_USERNAME/Pragya_QuadB_Tech.git

# Navigate to the project directory
cd Pragya_QuadB_Tech/week2/day2/trackr

# Install dependencies
yarn install
# or
npm install

# Start the development server
yarn dev
# or
npm run dev
```
Ensure you have a valid Solana wallet and sufficient test SOL in your devnet account.

## Transactions

- **Increment Counter**: Sends a transaction to increase the stored counter.
- **Decrement Counter**: Sends a transaction to decrease the stored counter.
- **Transaction History**: Displays recent transactions related to the counter.
