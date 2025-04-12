import { useState, useEffect } from "react";
import { getContract } from "./contract";

export const recordTransaction = async () => {
    try {
        const contract = getContract();
        if (!contract) return;

        const signer = await contract.signer;
        const gasPrice = await signer.provider.getFeeData(); // Fetch current gas price

        const tx = await contract.recordTransaction(21000, { gasPrice: gasPrice.gasPrice }); // Replace 21000 with actual gas used
        await tx.wait(); // Wait for transaction to be mined

        console.log("Transaction recorded successfully");
    } catch (error) {
        console.error("Error recording transaction:", error);
    }
};

