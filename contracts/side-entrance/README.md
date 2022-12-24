> A surprisingly simple lending pool allows anyone to deposit ETH, and withdraw it at any point in time.
> 
> 
> This very simple lending pool has 1000 ETH in balance already, and is offering free flash loans using the deposited ETH to promote their system.
> 
> You must take all ETH from the lending pool.
> 

**⇒ what does that mean ?** 

The pools get ETH and we need to find a way to take all of its ether

**⇒ what are my degree of freedom as an EoA ?
+⇒  How does the contract works ?**

- I can deposit ETH to increase balances[msg.sender] value
- I can withdraw all my balance (cannot withdraw partially), it uses the Address.sendValue function to send the ETH which revert if :
    - the targeted address is not a contract
    - the caller contract does not have enough ETH
- I can call the flashLoan function which call the `execute()` function from a contract with `{value:amount }` 
in solidity if the function does not exists, this is the fallback function that will be call

at the end, the contract checks if the amount has been paid back

This means the contract checks if its balance is the same as before the flashloan 

```solidity
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping (address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back");        
    }
}
```

If we read this contract, we see that we just need to make sure the pool gets its funds back at the end. 
So, what I could do is simple use the flashloan and call the `deposit()` function with the loaned ETH to increase my balance, while in the same time giving the funds back to the pool.

That is where is the vulnerability : the deposit function do not make any checks before increasing the balance.

A quick fix would be to set a flag in the flashLoan function at the begining before calling the external contract, and to remove it when its finished. 

The deposit function would then require the flag to be FALSE to be executable as implemented here:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPoolFIXED {
    using Address for address payable;

    mapping (address => uint256) public balances;
    bool flashLoanInProgress;

    function deposit() external payable {
        require(!flashLoanInProgress);
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");
        flashLoanInProgress = true;
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
        require(address(this).balance >= balanceBefore, "Flash loan hasn't been paid back"); 
        flashLoanInProgress = true;
    }
}
```

PS : in this challenge, I used extensively the hardhat/console.sol library to understand what is happening under the hood

```solidity
(node:12896) [DEP0147] DeprecationWarning: In future versions of Node.js, fs.rmdir(path, { recursive: true }) will be removed. Use fs.rm(path, { recursive: true }) instead
(Use `node --trace-deprecation ...` to show where the warning was created)

  [Challenge] Side entrance
deployer:  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
attacker:  0x70997970C51812dc3A010C7d01b50e0d17dc79C8
INIT

pool address:  0x5FbDB2315678afecb367f032d93F642f64180aa3
LenderPool.deposit():
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
1000000000000000000000
msg.sender balance:
1000000000000000000000
pool balance:
1000000000000000000000

EXPLOIT
poolAttacker address:  0x8464135c8F25Da09e49BC8782676a84730C318bC
    √ Exploit (76ms)

-- attack calls flashLoan --

-- flashLoan calls execute --

PoolAttacker.execute():
0x5fbdb2315678afecb367f032d93f642f64180aa3
1000000000000000000000
PoolAttacker balance:
1000000000000000000000

-- execute calls deposit --
LenderPool.deposit():
0x5fbdb2315678afecb367f032d93f642f64180aa3
1000000000000000000000
msg.sender balance:
1000000000000000000000
pool balance:
1000000000000000000000

-- final deposit --
LenderPool.deposit():
0x8464135c8f25da09e49bc8782676a84730c318bc
1000000000000000000000
```

## Smart contract

N **files :**

- 

N **libraries :**

- 

### Contract1.sol

> Description
> 

N **functions :**

- 

> notes
>