# 🔐 Reentrancy Vault Attack

A Solidity smart contract demo of the **Reentrancy vulnerability** and how attackers can exploit poorly ordered external calls to drain funds. This project simulates both the vulnerable contract (`Vault`) and an attacker contract (`Attacker`) to demonstrate the classic **reentrancy attack vector**.

---

## 📌 What’s Inside?

- ☑️ A vulnerable vault that allows deposits and withdrawals
- ⚠️ Exploitable logic that sends ETH before updating state
- 💣 A malicious contract that performs a reentrancy attack
- 🛠️ A secure version showing the correct pattern to fix it
- 📜 Deployer script to run the full attack on a testnet (Sepolia)

---

## 🧠 Concepts Covered

- Smart contract vulnerabilities in Solidity
- Reentrancy attacks & fallback functions
- Proper withdraw pattern (`Checks-Effects-Interactions`)
- ETH transfer methods and gas implications
- Testing and deploying on Sepolia testnet

---

## 🧪 How It Works

1. Vault is deployed and funded with ETH  
2. Attacker deposits a small amount and calls `withdraw()`  
3. During withdrawal, attacker re-enters before balance is set to 0  
4. Funds are drained through recursive calls  
5. Final balances are printed to show the effect of the exploit  

---

## ⚙️ Tech Stack

- Solidity
- Hardhat
- Sepolia Testnet
- JavaScript (Deployment Scripts)

---

## 🚀 Commands

```bash
# Initialize Hardhat
npx hardhat init

# Compile contracts
npx hardhat compile

# Deploy locally
npx hardhat run scripts/deploy.js

# Deploy & run attack on Sepolia
npx hardhat run scripts/deploy.js --network sepolia

---
```
## 📸 Screenshots

<details>
  <summary>✅ Initialized Hardhat Project</summary>
  <br>
  <img src="https://github.com/Pragyaa3/Pragya_QuadB_Tech/blob/main/week3/day3/reentrancy-vault/Eth_0.png?raw=true" alt="Initialized Hardhat" width="700"/>
</details>

<details>
  <summary>📥 Local Deployment (with vulnerability)</summary>
  <br>
  <img src=https://github.com/Pragyaa3/Pragya_QuadB_Tech/blob/main/week3/day3/reentrancy-vault/Eth_2.0.png?raw=true" width="700"/>
</details>

<details>
  <summary>📥 Local Deployment (after fix)</summary>
  <br>
  <img src="https://github.com/Pragyaa3/Pragya_QuadB_Tech/blob/main/week3/day3/reentrancy-vault/Eth_2.1%20.png?raw=true" alt="Local Fixed Deployment" width="700"/>
</details>

<details>
  <summary>💣 Sepolia Deployment (with vulnerability)</summary>
  <br>
  <img src="https://github.com/Pragyaa3/Pragya_QuadB_Tech/blob/main/week3/day3/reentrancy-vault/Sep_2.png?raw=true" width="700"/>
</details>

<details>
  <summary>🛡️ Sepolia Deployment (after fix)</summary>
  <br>
  <img src="https://github.com/Pragyaa3/Pragya_QuadB_Tech/blob/main/week3/day3/reentrancy-vault/Sep_1.png?raw=true" alt="Sepolia Fixed Deployment" width="700"/>
</details>

