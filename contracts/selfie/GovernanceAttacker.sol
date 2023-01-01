// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDVTSnapshot {
    function snapshot() external returns (uint256);
}

interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

contract RewardAttacker {

    address owner;

    IDVTSnapshot governanceToken;
    ISelfiePool selfiePool;
    ISimpleGovernance simpleGovernance;
    uint256 amount;

    constructor(
        address _governanceToken,
        address _selfiePool,
        address _simpleGovernance
        ) {
        owner = msg.sender;
        governanceToken = IDVTSnapshot(_governanceToken);
        selfiePool = ISelfiePool(_selfiePool);
        simpleGovernance = ISimpleGovernance(_simpleGovernance);
    }

    //this is the function that will call the SelfiePool.flashLoan function
    function attackRewardPool() external {
    }

    //this is the function called by the pool
    function receiveTokens(address token, uint256 loanAmount) external payable {
        
    }
}
