// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool_Logs {
    using Address for address payable;

    mapping (address => uint256) public balances;

    function deposit() external payable {
        ///LOG///
        console.log("LenderPool.deposit():");
        console.log(msg.sender);
        console.log(msg.value);
        ///LOG///

        balances[msg.sender] += msg.value;

        ///LOG///
        console.log("msg.sender balance:");
        console.log(balances[msg.sender]);

        console.log("pool balance:");
        console.log(address(this).balance);
        ///LOG///
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        console.log("amountToWithdraw: ");
        console.log(amountToWithdraw);
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");
        console.log("\n-- flashLoan calls execute --");
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        ///LOG///
        console.log("-- returning from execute to flashLoan --");
        console.log("balanceBefore:");
        console.log(balanceBefore);
        console.log("balanceAfter:");
        console.log(address(this).balance);
        ///LOG///
        
        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");        
    }
}
 