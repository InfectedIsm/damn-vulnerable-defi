# Selfie

> A new cool lending pool has launched! It's now offering flash loans of DVT tokens.
> 
> 
> Wow, and it even includes a really fancy governance mechanism to control it.
> 
> What could go wrong, right ?
> 
> You start with no DVT tokens in balance, and the pool has 1.5 million. Your objective: take them all.
> 

**⇒ what does that mean ?** 

**⇒ what are my degree of freedom as an EoA ?**

**⇒  How does the contract works ?**

solution : make a flashloan of DVT of all the supply, then snapshot the balances, then queue an action to drain all the funds in SelfiePool

==========================================

## Smart contract

3 **files :**

- SelfiePool.sol
- SimpleGovernance.sol
- DamnValuableTokenSnapshot.sol

N **libraries :**

- 

__________________________________________________________________________________

### SelfiePool.sol

> A pool offering flashloans of DVT tokens (represented by the DamnValuableTokenSnapshot.sol contract). It also has the ability to send all funds stored in the pool using the `drainAllFunds` function, which is role-protected to only be callable by the **SimpleGovernance** contract
> 

N **functions :**

- 

> notes
> 

---

### SimpleGovernance.sol

> A Governance protocol where **actions** can be proposed by a user that has at least half of the DVT Token using the `queueAction` function.
For an **action** to ****be executed, a specific delay must be respected. Also, an action can only be executed once.
An action contain a **data and weiAmount** parameter which is then fed into a `{Address.functionCallWithValue}` function
> 

N **functions :**

- 

> notes
> 

---

### DamnValuableTokenSnapshot.sol

> ERC20Snapshot Token with DVT symbol, minted with an `initialSupply` to msg.sender on construction
This contract is able to take snapshot of balances (users and supply) at a specific time, stored in a mapping and associated to an ID
> 

3 **functions :**

- snapshot()
- getBalanceAtLastSnapshot()
- getTotalSupplyAtLastSnapshot()

> notes
> 

[Medium](https://www.notion.so/Medium-6ed1115aa5044936a415171ad87d569c)