// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Nft, Currency, Token} from "../src/tokens.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Sale is Ownable {
    
    address saleOwner;
    bool private initialized;
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
    error NftDoesNotExist();
    error ErrorListing1155();

    constructor() Ownable(msg.sender) {
        require(!initialized, "Contract instance has already been initialized");
        initialized=true;
        saleOwner=msg.sender;
    }
 
    function listNft721(address _nftContractAddress,address _ERC20address,uint256 _tokenID, uint256 _price) public {
        require(Nft(_nftContractAddress).ownerOf(_tokenID)==msg.sender, NotOwner(msg.sender,Nft(_nftContractAddress).ownerOf(_tokenID)));
        idToMarketItem[_tokenID][_nftContractAddress]=MarketItem(_tokenID,msg.sender,_nftContractAddress,_ERC20address,_price,true); 
        saleExists[_tokenID][_nftContractAddress]=true;
    }

    function listNft1155(address _nftContractAddress,address _ERC20address,uint256 _tokenID, uint256 _price) public {
        require(Token(_nftContractAddress).balanceOf(msg.sender, _tokenID)!=0, ErrorListing1155());
        idToMarketItem[_tokenID][_nftContractAddress]=MarketItem(_tokenID,msg.sender,_nftContractAddress,_ERC20address,_price,true); 
        saleExists[_tokenID][_nftContractAddress]=true;
    }


    function purchaseNft721(address nftAddress, uint256 tokenId) public payable {
        require(saleExists[tokenId][nftAddress],SaleDoesNotExists());
        MarketItem memory listedItem = idToMarketItem[tokenId][nftAddress];
        uint256 fees = (listedItem.price*55)/(10000);
        uint256 sellerAmount=listedItem.price-fees;
        saleExists[tokenId][nftAddress]=false;
        delete (idToMarketItem[tokenId][nftAddress]);
        if(listedItem.paymentAddress==address(0)){
            require(msg.value>=listedItem.price, LessEther(msg.value,listedItem.price));
            (bool sent, ) = listedItem.sellerAdderess.call{value: sellerAmount}("");
            require(sent, EtherNotSent());
            sellerEarnings[saleOwner]+=fees;
        }
        else{
            Currency(listedItem.paymentAddress).transferCurrencyFrom(msg.sender,listedItem.sellerAdderess,sellerAmount);
            Currency(listedItem.paymentAddress).transferCurrencyFrom(msg.sender,saleOwner,fees);
            sellerEarnings[saleOwner]+=fees;
        }
        Nft(nftAddress).transferAssetFrom(listedItem.sellerAdderess, msg.sender, tokenId);
    }

    function purchaseNft1155(address nftAddress, uint256 tokenId) public payable {
        require(saleExists[tokenId][nftAddress],SaleDoesNotExists());
        MarketItem memory listedItem = idToMarketItem[tokenId][nftAddress];
        uint256 fees = (listedItem.price*55)/(10000);
        uint256 sellerAmount=listedItem.price-fees;
        saleExists[tokenId][nftAddress]=false;
        delete (idToMarketItem[tokenId][nftAddress]);
        if(listedItem.paymentAddress==address(0)){
            require(msg.value>=listedItem.price, LessEther(msg.value,listedItem.price));
            (bool sent, ) = listedItem.sellerAdderess.call{value: sellerAmount}("");
            require(sent, EtherNotSent());
            sellerEarnings[saleOwner]+=fees;
        }
        else{
            Currency(listedItem.paymentAddress).transferCurrencyFrom(msg.sender,listedItem.sellerAdderess,sellerAmount);
            Currency(listedItem.paymentAddress).transferCurrencyFrom(msg.sender,saleOwner,fees);
            sellerEarnings[saleOwner]+=fees;
        }
        Token(nftAddress).transferTokenFrom(listedItem.sellerAdderess, msg.sender, tokenId);
    }

    function getSeller(address nftAddress, uint256 tokenId) public view returns(address) {
        return idToMarketItem[tokenId][nftAddress].sellerAdderess;
    }

}