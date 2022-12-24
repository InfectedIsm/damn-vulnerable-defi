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
contract SideEntranceLenderPoolFIXED {
    using Address for address payable;

    mapping (address => uint256) public balances;
    bool flashLoanInProgress;

    function deposit() external payable {
        require(!flashLoanInProgress);
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");
        flashLoanInProgress = true;
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back"); 
        flashLoanInProgress = true;
    }
}
 