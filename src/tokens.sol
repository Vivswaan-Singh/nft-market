// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Nft is ERC721{
    constructor() ERC721("NFT","nft") {}
    
    function mintAssets(uint256 tokenID) public {
        _mint(msg.sender, tokenID);
    }

    function transferAssetFrom(address from, address to, uint256 tokenID) public {
        _transfer(from, to, tokenID);
    }

}

// nft owner 0xdD870fA1b7C4700F2BD7f44238821C26f7392148
// buyer 0x583031D1113aD414F02576BD6afaBfb302140225

contract Token is ERC1155{
    constructor() ERC1155("") {}
    
    function mintAssets(uint256 tokenID,uint256 amount) public {
        _mint(msg.sender, tokenID,amount,"");
    }

    function transferTokenFrom(address from, address to, uint256 tokenID) public {
        //_transfer(from, to, tokenID);
    }

}

contract Currency is ERC20, Ownable{
    constructor() ERC20("Currency","CRR") Ownable(msg.sender) {}

    function mintCoins(uint256 amount) public  {
        _mint(msg.sender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) override public returns(bool) {
        require(amount<=balanceOf(from));
        _transfer(from, to, amount);
        return true;
    }
}