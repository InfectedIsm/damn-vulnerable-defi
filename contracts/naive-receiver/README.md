> There's a lending pool offering quite expensive flash loans of Ether, which has 1000 ETH in balance.
You also see that a user has deployed a contract with 10 ETH in balance, capable of interacting with the lending pool and receiveing flash loans of ETH.
Drain all ETH funds from the user's contract. Doing it in a single transaction is a big plus ;)
> 

**⇒ what does that mean ?** 

draining all ETH from user contract (Receiver) means finding a way to make him ~~transfer us his 10 ETH.~~

> That’s where I was wrong, to win the challenge we just need to drain the contract from its ETH, no need to steal them. In fact, the test file shows that the drained funds must be in the pool
> 

```solidity
expect(
            await ethers.provider.getBalance(this.receiver.address)
        ).to.be.equal('0');
        expect(
            **await ethers.provider.getBalance(this.pool.address)
        ).to.be.equal(ETHER_IN_POOL.add(ETHER_IN_RECEIVER));**
```

There’s no way to make him approve sth as this is not an ERC20

As the user contracts makes flashloans with a pool, there could be a vunerability in their interaction

**⇒ what are my degree of freedom as an EoA ?**
The Receiver contract have a public function calling the pool with a reentrant call (Address.sendValue)
The only way to receive ETH from the receiver is through the pool.sendValue call, but pool is hardcoded into the contract during construction.

~~I could rewrite the pool address if I can make this contract call my own contract and execute a delegatecall ?~~

**The Lender contract have an external function flashLoan(add borrower, uint256 amount) checking the first argument is a contract, but don’t check if the called contract is msg.sender…** 

**⇒  How does the contract works ?**

There’s 2 contracts, the Lender contract which offer ETH flashloans to user through a Receiver contract. 

## Smart contract

2 **files :**

- FlashLoanReceiver.sol
- NaiveReceiverLenderPool.sol

**2 libraries :**

- Address.sol
- ReentrancyGuard.sol

### FlashLoanReceiver.sol

This contract is deployed by a user who wants to takes flashloans from the Lender contract
it uses Address.sol for address

N **functions :**

- **receiveEther(uint256 fee) public payable**
can only be called from the pool it has been deployed to
It is called from a pool, and send ETH (amountToBeRepaid) to the pool
⚠ uses the Address.sol sendValue(amount) method which is subject to reentrancy
⚠ & the function don’t have the nonReentrant modifier
⚠ call the sendValue method from Address.sol, which use the call solidity function
- **_executeActionDuringFlashLoan() internal**
no code inside, is called in receiveEther
- **receive () external payable**

> Notes
> 

### NaiveReceiverLenderPool.sol

This is the flashloan contract
It inherit from ReentrancyGuard 
it uses Address.sol for address

N **functions :**

- **fixedFee() external pure returns (uint256)**
return the value of the uint256 constant FIXED_FEE = 1 ETH
- **flashLoan(address borrower, uint256 borrowAmount) external nonReentrant**

> Notes
>