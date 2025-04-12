import { useState, useEffect } from "react";
import { getContract } from "../src/contract";

const GasFeeComparison = () => {
    const [contract, setContract] = useState(null);
    const [transactions, setTransactions] = useState([]);
    const [selectedTx1, setSelectedTx1] = useState(null);
    const [selectedTx2, setSelectedTx2] = useState(null);
    const [result, setResult] = useState(null);

    // Get contract after component mounts (client-side only)
    useEffect(() => {
        const fetchContract = async () => {
            const c = await getContract();
            setContract(c);
        };

        fetchContract();
    }, []);

    // Fetch transactions when contract is available
    useEffect(() => {
        const fetchTransactions = async () => {
            if (!contract) return;

            try {
                const transactionCount = await contract.getTransactionCount();
                let txList = [];

                for (let i = 0; i < transactionCount; i++) {
                    let tx = await contract.getTransaction(i);
                    txList.push({
                        index: i,
                        sender: tx[0],
                        gasUsed: tx[1].toString(),
                        gasPrice: tx[2].toString(),
                    });
                }

                setTransactions(txList);
            } catch (error) {
                console.error("Error fetching transactions:", error);
            }
        };

        fetchTransactions();
    }, [contract]);

    const compareTransactions = async () => {
        if (!contract || selectedTx1 === null || selectedTx2 === null) {
            alert("Please select two transactions");
            return;
        }

        try {
            const result = await contract.compareGas(Number(selectedTx1), Number(selectedTx2));
            console.log("Comparison Result:", result);
            setResult(result);
        } catch (error) {
            console.error("Error comparing transactions:", error);
        }
    };

    return (
        <div>
            <h2>Compare Gas Fees</h2>
            <label>Select First Transaction:</label>
            <select onChange={(e) => setSelectedTx1(e.target.value)}>
                <option value="">Select Transaction</option>
                {transactions.map((tx) => (
                    <option key={tx.index} value={tx.index}>
                        Tx {tx.index} - Gas Used: {tx.gasUsed}, Gas Price: {tx.gasPrice}
                    </option>
                ))}
            </select>

            <label>Select Second Transaction:</label>
            <select onChange={(e) => setSelectedTx2(e.target.value)}>
                <option value="">Select Transaction</option>
                {transactions.map((tx) => (
                    <option key={tx.index} value={tx.index}>
                        Tx {tx.index} - Gas Used: {tx.gasUsed}, Gas Price: {tx.gasPrice}
                    </option>
                ))}
            </select>

            <button onClick={compareTransactions}>Compare</button>

            {result && <p>Comparison Result: {result}</p>}
        </div>
    );
};

export default GasFeeComparison;
