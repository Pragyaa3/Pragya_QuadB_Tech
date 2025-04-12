const hre = require("hardhat");

async function main() {
    // Deploy contract
    const gasFeeComparator = await hre.ethers.deployContract("GasFeeComparator");
    await gasFeeComparator.waitForDeployment(); // Ensure deployment is complete

    console.log("GasFeeComparator deployed to:", await gasFeeComparator.getAddress());
}

// Run the script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
