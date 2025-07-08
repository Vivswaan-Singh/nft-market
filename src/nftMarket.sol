// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Nft, Currency, Token} from "../src/tokens.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Sale is Ownable {
    uint256 private _nextTokenId;
    uint256 private _listedNfts;

    mapping(uint256=>mapping(address=>MarketItem)) public idToMarketItem;
    mapping(uint256=>mapping(address=>bool)) public saleExists;
    mapping(address => uint256) private sellerEarnings;

    struct MarketItem { 
        uint256 tokenID;
        address sellerAdderess;
        address nftContractaddress;
        address paymentAddress;
        uint256 price;
        bool active;
    }

    error NotOwner(address yourAddress, address ownerAddress);
    error SaleDoesNotExists();
    error EtherNotSent();
    error LessEther(uint256 sent,uint256 needed);

    constructor() Ownable(msg.sender) {}
 
    function listNft721(address _nftContractAddress,address _ERC20address,uint256 _tokenID, uint256 _price) public {
        require(Nft(_nftContractAddress).ownerOf(_tokenID)==msg.sender, NotOwner(msg.sender,Nft(_nftContractAddress).ownerOf(_tokenID)));
        _listedNfts++;
        idToMarketItem[_tokenID][_nftContractAddress]=MarketItem(_tokenID,msg.sender,_nftContractAddress,_ERC20address,_price,true); 
        saleExists[_tokenID][_nftContractAddress]=true;
    }


    function purchaseNft721(address nftAddress, uint256 tokenId) public payable {
        require(saleExists[tokenId][nftAddress],SaleDoesNotExists());
        MarketItem memory listedItem = idToMarketItem[tokenId][nftAddress];
        if(listedItem.paymentAddress==address(0)){
            require(msg.value>=listedItem.price, LessEther(msg.value,listedItem.price));
            (bool sent, ) = listedItem.sellerAdderess.call{value: listedItem.price}("");
            require(sent, EtherNotSent());
        }
        else{
            Currency(listedItem.paymentAddress).transferFrom(msg.sender,listedItem.sellerAdderess,listedItem.price);
        }
        Nft(nftAddress).transferAssetFrom(listedItem.sellerAdderess, msg.sender, tokenId);
        delete (idToMarketItem[tokenId][nftAddress]);
        _listedNfts--;
        saleExists[tokenId][nftAddress]=false;
    }

    function getSeller(address nftAddress, uint256 tokenId) public view returns(address) {
        return idToMarketItem[tokenId][nftAddress].sellerAdderess;
    }

}
