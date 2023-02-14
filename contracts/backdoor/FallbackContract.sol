// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "hardhat/console.sol";

contract FallbackContract {

    IERC20 public token;
    address private owner;
    constructor(address _token, address _owner) {
        token = IERC20(_token);
        owner = _owner;
        console.log("FallbackContract deployed with token: %s", _token);
    }

    receive() external payable {
    }
    fallback() external payable {
        console.log("Fallback called with msg.sender: %s", msg.sender);
        console.log("msg.sender:%s is approving spender:%s to spend %s", msg.sender, owner, 10 ether);
        console.log("of token:%s", address(token));
        console.log("address(this):%s", address(this));
        token.approve(owner, 10 ether);
    }
}
