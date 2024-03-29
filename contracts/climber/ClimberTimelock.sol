// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";


/**
 * @title ClimberTimelock
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ClimberTimelock is AccessControl {
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    // Possible states for an operation in this timelock contract
    enum OperationState {
        Unknown,
        Scheduled,
        ReadyForExecution,
        Executed
    }

    // Operation data tracked in this contract
    struct Operation {
        uint64 readyAtTimestamp;   // timestamp at which the operation will be ready for execution
        bool known;         // whether the operation is registered in the timelock
        bool executed;      // whether the operation has been executed
    }

    // Operations are tracked by their bytes32 identifier
    mapping(bytes32 => Operation) public operations;

    uint64 public delay = 1 hours;

    constructor(
        address admin,
        address proposer
    ) {
        //@audit-info deployer + Timelock have ADMIN_ROLE and PROPOSER_ROLE
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, ADMIN_ROLE);

        // deployer + self administration
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, address(this));

        //@audit-info proposer + Timelock have PROPOSER_ROLE
        _setupRole(PROPOSER_ROLE, proposer);
    }

    function getOperationState(bytes32 id) public view returns (OperationState) {
        Operation memory op = operations[id];
        
        if(op.executed) {
            return OperationState.Executed;
        } else if(op.readyAtTimestamp >= block.timestamp) {
            return OperationState.ReadyForExecution;
        } else if(op.readyAtTimestamp > 0) {
            return OperationState.Scheduled;
        } else {
            return OperationState.Unknown;
        }
    }

    function getOperationId(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(targets, values, dataElements, salt));
    }
    //@audit-info protected by onlyRole(PROPOSER_ROLE)
    //@audit can I schedule an operation even if I am not the proposer/admin ? Can I trick the proposer to schedule an operation ?
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external onlyRole(PROPOSER_ROLE) {
        console.log("Timelock.schedule: entered by %s", msg.sender);
        require(targets.length > 0 && targets.length < 256);
        require(targets.length == values.length);
        require(targets.length == dataElements.length);

        bytes32 id = getOperationId(targets, values, dataElements, salt);
        console.log("id: %s", uint256(id));
        require(getOperationState(id) == OperationState.Unknown, "Operation already known");
        
        operations[id].readyAtTimestamp = uint64(block.timestamp) + delay;
        operations[id].known = true;
    }

    /** Anyone can execute what has been scheduled via `schedule` */
    //@audit execute is not protected by any role, if the target is the Timelock
    // this means I can force the Timelock to execute any of its own role-protected functions like schedule
    // First stp is to set the new delay to 0 so that the require in schedule is bypassed for the operations[id]
    // Then as a second step, I can schedule the set of operations[id] I'm currently executing 
    // Finally, I can set me as the new sweeper in the vault
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable {
        //@audit-info targets.length could be cached to save gas
        console.log("ClimberTimelock.execute: entered by %s", msg.sender);
        require(targets.length > 0, "Must provide at least one target");
        require(targets.length == values.length);
        require(targets.length == dataElements.length);

        bytes32 id = getOperationId(targets, values, dataElements, salt);
        console.log("id: %s", uint256(id));

        for (uint8 i = 0; i < targets.length; i++) {
            console.log("operation n_%s", i);
            //@audit external call: can be exploited ? ==> yes, check audit line 95
            targets[i].functionCallWithValue(dataElements[i], values[i]);
        }
        //@audit can this require be tricked ? To do so we need op.readyAtTimestamp >= block.timestamp
        require(getOperationState(id) == OperationState.ReadyForExecution, "Operation not ready for execution");
        operations[id].executed = true;
    }

    function updateDelay(uint64 newDelay) external {
        console.log("ClimberTimelock.updateDelay: entered by %s", msg.sender);
        require(msg.sender == address(this), "Caller must be timelock itself");
        require(newDelay <= 14 days, "Delay must be 14 days or less");
        delay = newDelay;
    }

    receive() external payable {}
}
