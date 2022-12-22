# Truster

> More and more lending pools are offering flash loans. In this case, a new pool has launched that is offering flash loans of DVT tokens for free.
> 
> 
> Currently the pool has 1 million DVT tokens in balance. And you have nothing.
> 
> But don't worry, you might be able to take them all from the pool. In a single transaction.
> 

**⇒ what does that mean ?** 

the balance of the Lender on the DVT contract is 1 million DVT, we must find a way to transfer these token from the Lender to ourselves, either by making the contract ERC20.Transfer to us, or ERC20.approve to us then using ERC20.transferFrom

**⇒ what are my degree of freedom as an EoA ?**

If I want to call the flashLoan function of the contract, I must give to it a contract as the “target” parameter, as the Address.functionCall (L36) require the target address to be a contract (see doc)
In fact, I already found the vulnerability here : functionCall itself calls the solidity CALL function, and take any calldata as input.
I can write a contract with a malicious function making the Lender call the ERC20.transfer or ERC20.approve function, building the calldata of this function with the right parameter and gives it as input of the L36 Address.functionCall  

**⇒  How does the contract works ?**

The Lender transfer tokens to the user, then call a function from any smart contract the user chose using the Address.functionCall(data) function, which itself use the solidity call function.

Then at the end when the user finished executing the call, the Lender checks if its balance is the same as before the call, if not it reverts.

delegatecall execute the code of the callee (DVT) in the context of the caller (Victim), that means that the function executed changes states **in the victim contract**

This cannot work for this challenge.

I tried 2 approach :

- one with delegatecall, and this one didn’t work but thanks to that I was finally able to fully understand (and remember) the usage of this function, and its vulnerability (which does not apply in this example)
- the other one which is simply this function into an attack contract :

```solidity
function attackLender() external {
        require(msg.sender == owner);
        uint256 victimBalance =  damnValuableToken.balanceOf(victim);
        ILender(victim).flashLoan(
            0,
            owner,
            address(damnValuableToken),
            abi.encodeWithSignature("approve(address,uint256)",owner,victimBalance) 
        );
        uint256 victimAllowance =  damnValuableToken.allowance(victim,owner);
        emit allowanceNow(victimAllowance);
    }
```

If we read this function line by line :

L1 : I don’t want someone else to be able to use my attack contract, so I restrict this function to myself

L2 : I check what is the total balance of the victim

L3-8 : I call the Lender flashloan function with these parameters : 

borrowAmount ⇒ 0
borrower ⇒ myself, doesn’t really matters here, I could have used any value, but address(0) 
target ⇒ the DamnValuableToken address
calldata data ⇒ the abi encoding of the approve function of the DamnValuableToken contract

If we look more in details into this call :

`abi.encodeWithSignature("approve(address,uint256)",owner,victimBalance)`

This means the lender call the approve function and is approving all his balance to the attacker

Then, all I need to do is use the ERC20.transferFrom function to get all the tokens.