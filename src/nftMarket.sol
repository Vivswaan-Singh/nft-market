// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Nft, Currency, Token} from "../src/tokens.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Sale is Ownable {
    
    address saleOwner;
    mapping(uint256=>mapping(address=>MarketItem)) public idToMarketItem;
    mapping(uint256=>mapping(address=>bool)) public saleExists;
    mapping(address => uint256) private sellerEarnings;
 
    struct MarketItem { 
        uint256 tokenID;
        address sellerAdderess;
        address nftContractaddress;
        address paymentAddress;
        uint256 price;
        uint256 amount;
        bool isERC721;
    }

    error NotOwner(address yourAddress, address ownerAddress);
    error SaleDoesNotExists();
    error EtherNotSent();
    error EtherNotSentBack();
    error LessEther(uint256 sent,uint256 needed);
    error NftDoesNotExist();
    error ErrorListing1155();
    error NotEnoughTokens(uint256 demand,uint256 available);

    constructor() Ownable(msg.sender) {
        saleOwner=msg.sender;
    }
 
    function listNft721(address _nftContractAddress,address _ERC20address,uint256 _tokenID, uint256 _price) public {
        require(Nft(_nftContractAddress).ownerOf(_tokenID)==msg.sender, NotOwner(msg.sender,Nft(_nftContractAddress).ownerOf(_tokenID)));
        idToMarketItem[_tokenID][_nftContractAddress]=MarketItem(_tokenID,msg.sender,_nftContractAddress,_ERC20address,_price,1,true); 
        saleExists[_tokenID][_nftContractAddress]=true;
    }

    function listNft1155(address _nftContractAddress,address _ERC20address,uint256 _tokenID, uint256 _price, uint256 _amount) public {
        require(Token(_nftContractAddress).balanceOf(msg.sender, _tokenID)!=0, ErrorListing1155());
        idToMarketItem[_tokenID][_nftContractAddress]=MarketItem(_tokenID,msg.sender,_nftContractAddress,_ERC20address,_price,_amount,false); 
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
            (bool sentback, ) = msg.sender.call{value: msg.value-listedItem.price}("");
            require(sentback, EtherNotSentBack());
            sellerEarnings[saleOwner]+=fees;
        }
        else{
            ERC20(listedItem.paymentAddress).transferFrom(msg.sender,listedItem.sellerAdderess,sellerAmount);
            ERC20(listedItem.paymentAddress).transferFrom(msg.sender,saleOwner,fees);
            sellerEarnings[saleOwner]+=fees;
        }
        ERC721(nftAddress).transferFrom(listedItem.sellerAdderess, msg.sender, tokenId);
    }

    function purchaseNft1155(address nftAddress, uint256 tokenId, uint256 amount) public payable {
        require(saleExists[tokenId][nftAddress],SaleDoesNotExists());
        MarketItem memory listedItem = idToMarketItem[tokenId][nftAddress];
        require(amount<=listedItem.amount,NotEnoughTokens(amount,listedItem.amount));
        uint256 price = listedItem.price*amount;
        uint256 fees = (price*55)/(10000);
        uint256 sellerAmount = price-fees;
        idToMarketItem[tokenId][nftAddress].amount-=amount;
        if(idToMarketItem[tokenId][nftAddress].amount==0){
            saleExists[tokenId][nftAddress] = false;
            delete (idToMarketItem[tokenId][nftAddress]);
        }
        if(listedItem.paymentAddress==address(0)){
            require(msg.value>=price, LessEther(msg.value,price));
            (bool sent, ) = listedItem.sellerAdderess.call{value: sellerAmount}("");
            require(sent, EtherNotSent());
            (bool sentback, ) = msg.sender.call{value: msg.value-price}("");
            require(sentback, EtherNotSentBack());
            sellerEarnings[saleOwner]+=fees;
        }
        else{
            ERC20(listedItem.paymentAddress).transferFrom(msg.sender,listedItem.sellerAdderess,sellerAmount);
            ERC20(listedItem.paymentAddress).transferFrom(msg.sender,saleOwner,fees);
            sellerEarnings[saleOwner]+=fees;
        }
        ERC1155(nftAddress).safeTransferFrom(listedItem.sellerAdderess, msg.sender, tokenId, amount, "");
    }

    function getSeller(address nftAddress, uint256 tokenId) public view returns(address) {
        return idToMarketItem[tokenId][nftAddress].sellerAdderess;
    }

    function getSaleAddress() external view returns(address){
        return address(this);
    }

}