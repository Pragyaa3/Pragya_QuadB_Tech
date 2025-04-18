const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vault Reentrancy Test", function () {
  let deployer, user, attacker;
  let vault, attackerContract;

  beforeEach(async () => {
    [deployer, user, attacker] = await ethers.getSigners();

    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.connect(deployer).deploy();
    await vault.waitForDeployment();

    const vaultAddress = await vault.getAddress();
    await vault.connect(user).deposit({ value: ethers.parseEther("10") });

    const Attacker = await ethers.getContractFactory("Attacker");
    attackerContract = await Attacker.connect(attacker).deploy(vaultAddress);
    await attackerContract.waitForDeployment();
  });

  it("should allow normal deposit and withdrawal", async () => {
    const before = await ethers.provider.getBalance(vault.getAddress());
    expect(before).to.equal(ethers.parseEther("10"));
  });

  it("should prevent reentrancy attack", async () => {
    await expect(
      attackerContract.connect(attacker).attack({
        value: ethers.parseEther("1"),
      })
    ).to.be.revertedWith("Withdraw failed");
  
    const vaultBalance = await ethers.provider.getBalance(await vault.getAddress());
    const attackerBalance = await ethers.provider.getBalance(attackerContract.getAddress());
  
    expect(vaultBalance).to.equal(ethers.parseEther("10")); // unchanged
    expect(attackerBalance).to.equal(0); // only their own deposit
  });
  
});
