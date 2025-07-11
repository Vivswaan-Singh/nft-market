// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract Nft is ERC721{
    constructor() ERC721("NFT","nft") {}
    
    function mint(uint256 tokenID) public {
        _mint(msg.sender, tokenID);
    }
}


contract Token is ERC1155{
    constructor() ERC1155("") {}

    function mint(uint256 tokenID,uint256 amount) public {
        _mint(msg.sender, tokenID,amount,"");
    }
}

contract Currency is ERC20, Ownable{
    constructor() ERC20("Currency","CRR") Ownable(msg.sender) {}

    function mint(uint256 amount) public  {
        _mint(msg.sender, amount);
    }
}
