// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
    uint amount = balances[msg.sender];
    require(amount > 0, "Nothing to withdraw");

    // ❌ VULNERABLE: transfer before setting balance to 0
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] = 0;
}


    // Helper to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
