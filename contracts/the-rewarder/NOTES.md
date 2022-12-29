# The rewarder

> There's a pool offering rewards in tokens every 5 days for those who deposit their DVT tokens into it.
> 
> 
> Alice, Bob, Charlie and David have already deposited some DVT tokens, and have won their rewards!
> 
> You don't have any DVT tokens. But in the upcoming round, you must claim most rewards for yourself.
> 
> Oh, by the way, rumours say a new pool has just landed on mainnet. Isn't it offering DVT tokens in flash loans?
> 

**⇒ what does that mean ?** 

**⇒ what are my degree of freedom as an EoA ?**

I can make a flashloan of DVT, or deposit DVT to the rewarderPool… or I can do both too

**⇒  How does the project works ?**

## testfile logic

1. initiate the 5 contracts (including DVT)
2. gives 100 DVT each to alice, bob and charlie
3. alice, bob and charlie deposit their token to the RewarderPool
4. advance time 5 days
5. each depositor gets 25 reward tokens from the rewarderPool.distributeReward( ) function
6. 2 rounds have occurred so far
7. **EXPLOIT**
8. should be 3rd round here
9. rewarderPool.distributeReward( ) is called for each user
10. the rewards must have been issued to the attacker account
11. The amount of rewards earned should be really close to 100 tokens
12. Attacker finishes with zero DVT tokens in balance

## Smart contract

**4 files :**

- **AccountingToken**
    - *AccessControl*
- **FlashLoanerPool**
    - *ReentrancyGuard*
    - *Address*
    - *****************DamnValuableToken*****************
- **RewardToken**
    - *ERC20*
    - *AccessControl*
- **TheRewarderPool**

**6 libraries/imports :**

- ERC20
- ERC20Snapshot
- AccessControl
- Address
- ReentrancyGuard
- DamnValuableToken

### AccountingToken.sol

> A limited pseudo-ERC20 token keeping track of deposit and withdrawal with snapshotting capabilities
It is called by TheRewarderPool contract for its snapshot capability
> 

N **functions :**

- mint (with auth)
- burn (with auth)
- snapshot (with auth)

> I don’t see any vuln to attack in this contract rn, it does not make call to external contract, and roles cannot be modified after construction
well, it still check roles using msg.sender and do no verify msg.sender is tx.origin, this means I could possibly delegatecall with someone who has the right auth…
But no, the athorized account is an EOA (deployer) and phishing or eq are not part of CTFs
> 

### **FlashLoanerPool.sol**

> A pool that offer flashloans of DVT, it have 1M token at startup minted by the DVT contract
> 

N **functions :**

- flashLoan

> The function verify the caller is a contract because it uses the `Address.functionCall()` , and EOA cannot be called.
The called contract must have a `receiveFlashLoan(uint256)` , this is probably again where the vuln will apply.
> 

### RewardToken.sol

> ERC20 token given as reward for users of the pool
> 

1 **functions :**

- mint

> verification based on role, can be minted by the rewardToken contract only
> 

### TheRewarderPool.sol

> A contract where users can deposit DVT token in order to earn reward every 5 days (fixed by the constant `REWARD_ROUND_MIN_DURATION`)
When a user deposit DVT, equal value of `accounting` tokens is minted (the one from AccountingToken.sol with snapshot capabilities), and the `distributeRewards()` function is called, which will
> 

N **functions :**

- deposit(uint256 amountToDeposit) external
- withdraw(uint256 amountToWithdraw) external
- distributeRewards() public returns (uint256)
- _recordSnapshot() private
- _hasRetrievedReward(address account) private view returns (bool)
- isNewRewardsRound() public view returns (bool)

> notes
>