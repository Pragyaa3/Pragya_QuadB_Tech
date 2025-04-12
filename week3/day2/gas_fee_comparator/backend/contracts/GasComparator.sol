// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasFeeComparator {
    struct Transaction {
        address sender;
        uint256 gasUsed;
        uint256 gasPrice;
    }

    Transaction[] public transactions; // Stores all recorded transactions

    uint256[100] private largeArray; // ✅ Fixed storage array (declared at contract level)

    event TransactionRecorded(address indexed sender, uint256 gasUsed, uint256 gasPrice);

    // ✅ Function to perform storage operation and record gas usage
    function storageOperation() public {
        uint256 startGas = gasleft();

        largeArray[0] = 10; // ✅ Modify an already declared storage variable

        uint256 gasUsed = startGas - gasleft();
        transactions.push(Transaction(msg.sender, gasUsed, tx.gasprice));
        emit TransactionRecorded(msg.sender, gasUsed, tx.gasprice);
    }

    // ✅ Function to perform memory operation and record gas usage
    function memoryOperation() public {
        uint256 startGas = gasleft();

        uint256[100] memory tempArray; // Memory allocation (temporary)
        tempArray[0] = 10; // Modify memory variable

        uint256 gasUsed = startGas - gasleft();
        transactions.push(Transaction(msg.sender, gasUsed, tx.gasprice));
        emit TransactionRecorded(msg.sender, gasUsed, tx.gasprice);
    }

    // ✅ Function to compare two transactions based on gas used
    function compareGas(uint256 index1, uint256 index2) public view returns (string memory) {
        require(index1 < transactions.length && index2 < transactions.length, "Invalid transaction index");

        if (transactions[index1].gasUsed < transactions[index2].gasUsed) {
            return "Transaction 1 used less gas";
        } else if (transactions[index1].gasUsed > transactions[index2].gasUsed) {
            return "Transaction 2 used less gas";
        } else {
            return "Both transactions used the same gas";
        }
    }

    // ✅ Function to get transaction count
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    // ✅ Function to fetch transaction details
    function getTransaction(uint256 index) public view returns (address, uint256, uint256) {
        require(index < transactions.length, "Invalid index");
        Transaction memory txData = transactions[index];
        return (txData.sender, txData.gasUsed, txData.gasPrice);
    }
}
