# Unstoppable

There's a lending pool with a million DVT tokens in balance, offering flash loans for free.

If only there was a way to attack and stop the pool from offering flash loans...

You start with 100 DVT tokens in balance.

Stop the pool from offering flash loans 

**⇒ what does that mean ?** 
To stop the lending pool to offer flash loan, we need to block its logic or to remove all its funds
If we check the flashLoan function of the pool (UnstoppableLender.sol) we see that there are multiple check, if one of them is always wrong, flashloans are blocked forever.
For example, we could try to make poolBalance (always) ≠ balanceBefore 
This is maybe possible because poolBalance is managed by the Lender contract, while balanceBefore is the balance of the Lender on the DVT contract

**⇒ what are my degree of freedom as an EoA ?**
I can deploy the Receiver contract who can execute a flashloan from Lender

**⇒  How does the contract works ?**

A user create a Receiver contract to be able to get a DVT flashloan from the Lender contract

user interactable

## Smart contract

**3 files :**

- DamnValuableToken.sol
- ReceiverUnstoppable.sol
- UnstopableLender.sol

**2 libraries :**

- IERC20.sol
- ReentrancyGuard.sol

### DamnValuableToken.sol

Simple ERC20 token, mint max(uint256) to msg.sender on construction 

### ReceiverUnstoppable.sol

This contract’s goal is to execute a flashloan (Lender func) on behalf of msg.sender
It is deployed by any user who needs a loan from the Lender.
It communicate with the Lender protocol by borrowing assets, doing some actions with it 

**2 functions :**

- receiveToken(address tokenAddress, uint256 amount) external
can only be executed by the pool 
will transfer tokens from this.contract to pool.contract
- executeFlashLoan(uint256 amount) external
can only be executed by owner of this.contract
call pool.flashLoan(amount) function

Import UnstopableLender and IERC20

Constructor sets 2 values :

- pool which contains the address to the UnstoppableLender contract
- owner = msg.sender

### UnstoppableLender.sol

Pool contract that has only one token, DVT
A user can deposit DVT tokens to this.contract by first approving them to this.contract
⚠The pool do not track user’s own balance, only track pool balance

**2 functions :**

- depositTokens(uint256 amount) external **nonReentrant**
must deposit >0 tokens
this.contract transferFrom on behalft msg.sender 
Increment pool balance 
⚠no user balance
- flashLoan(uint256 borrowAmount) external **nonReentrant**
should only be called through a Receiver contract because a IReceiver(msg.sender).receiveToken call is made, and if called by an EoA this will result in an error as EoA do not have functions

## Test file