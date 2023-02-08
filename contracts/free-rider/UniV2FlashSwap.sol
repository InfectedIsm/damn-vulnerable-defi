// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IMarketPlace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address) external view returns (uint);
}


contract UniV2FlashSwap is IUniswapV2Callee, IERC721Receiver {

    IWETH9 private weth;
    IERC20 private token;
    IUniswapV2Factory private factory;
    IUniswapV2Pair private pair;

    IMarketPlace private marketplace;
    IERC721 private nft;
    address public buyer;

    // For this example, store the amount to repay
    uint public amountToRepay;

    constructor(address _factory, address _weth, address _token, address _marketplace, address _nft, address _buyer) {
        factory = IUniswapV2Factory(_factory);
        weth = IWETH9(_weth);
        token = IERC20(_token);
        pair = IUniswapV2Pair(factory.getPair(address(token), address(weth)));

        marketplace = IMarketPlace(_marketplace);
        nft = IERC721(_nft);
        buyer = _buyer;
    }

    function flashSwap(uint wethAmount, uint256[] calldata tokenIds) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(address(weth), msg.sender, tokenIds);

        // amount0Out is DAI, amount1Out is WETH
        pair.swap(wethAmount, 0, address(this), data);
    }

    // This function is called by the DVT/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) override external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, address caller, uint256[] memory tokenIds) = abi.decode(data, (address, address, uint256[]));
        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == address(weth), "token borrow != WETH");
        console.log("UniV2FlashSwap:amount0 %s", amount0);
        console.log("UniV2FlashSwap:contract weth balance %s", weth.balanceOf(address(this)));
        console.log("UniV2FlashSwap:contract token balance %s", token.balanceOf(address(this)));
        weth.withdraw(amount0);
        console.log("UniV2FlashSwap:weth withdrawn %s", amount0);
        marketplace.buyMany{value: amount0}(tokenIds);

        //transfer nft to buyer
        for (uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), buyer, tokenIds[i]);
            console.log("UniV2FlashSwap:transfered nft %s", tokenIds[i]);
        }

        // about 0.3% fee, +1 to round up
        uint fee = (amount0 * 3) / 997 + 1;
        amountToRepay = amount0 + fee;

        weth.deposit{value: amountToRepay}();
        // Transfer flash swap fee from caller
        // weth.transferFrom(caller, address(this), fee);

        // Repay
        weth.transfer(address(pair), amountToRepay);
    }

        function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        require(msg.sender == address(nft));
        require(_tokenId >= 0 && _tokenId <= 5);
        require(nft.ownerOf(_tokenId) == address(this));
        console.log("UniV2FlashSwap:owner of %s", _tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }
    receive() external payable {
        console.log("received %s", msg.value);
    }
}

