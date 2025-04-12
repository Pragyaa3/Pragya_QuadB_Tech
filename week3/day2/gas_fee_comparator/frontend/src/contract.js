import { ethers } from "ethers";
import GasFeeComparatorABI from "../contractABI.json";

const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

export const getContract = async () => {
    // Ensure it's running only in the browser
    if (typeof window === "undefined") {
        console.log("Server-side: skipping MetaMask check.");
        return null;
    }

    if (window.ethereum) {
        try {
            const provider = new ethers.BrowserProvider(window.ethereum);
            await window.ethereum.request({ method: "eth_requestAccounts" });
            const signer = await provider.getSigner();
            console.log("ABI Functions:", GasFeeComparatorABI.map(item => item.name || item.type));

            return new ethers.Contract(CONTRACT_ADDRESS, GasFeeComparatorABI, signer);
        } catch (error) {
            console.error("Error accessing MetaMask:", error);
            return null;
        }
    } else {
        alert("Please install MetaMask to use this application.");
        return null;
    }
};
