const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const [deployer] = await ethers.getSigners();

  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.connect(deployer).deploy();
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  console.log("✅ Vault deployed at:", vaultAddress);

  const depositTx = await vault.connect(deployer).deposit({
    value: ethers.parseEther("0.001"),
  });
  await depositTx.wait();
  console.log("📥 User deposited 0.001 ETH");

  const Attacker = await ethers.getContractFactory("Attacker");
  const attackerContract = await Attacker.connect(deployer).deploy(vaultAddress);
  await attackerContract.waitForDeployment();
  const attackerAddress = await attackerContract.getAddress();
  console.log("💀 Attacker deployed at:", attackerAddress);

  const attackTx = await attackerContract.connect(deployer).attack({
    value: ethers.parseEther("0.0002"),
  });
  await attackTx.wait();
  console.log("🚨 Attack executed");

  const vaultBalance = await ethers.provider.getBalance(vaultAddress);
  const attackerBalance = await ethers.provider.getBalance(attackerAddress);

  console.log("💰 Vault final balance:", ethers.formatEther(vaultBalance));
  console.log("🤑 Attacker contract balance:", ethers.formatEther(attackerBalance));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
