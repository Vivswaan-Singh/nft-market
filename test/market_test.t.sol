// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { Nft, Currency, Token} from "../src/tokens.sol";
import {Sale} from "../src/nftMarket.sol";

contract Market is Test {
    Sale public sale;
    Nft public nft;
    Currency public currency;
    Token public token;
    address addr1;
    address addr2;
    address addr3;
    address addr4;
    address addr5;
    address addr6;
    address saleAddr;

    event Seller(address addr);


    function setUp() public {
        sale = new Sale();
        nft = new Nft();
        currency = new Currency();
        token = new Token();
        addr1 = address(1);
        addr2 = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp,"200")))));
        addr3 = address(111);
        addr4 = address(1111);
        payableReceiver seller = new payableReceiver();
        addr5 = address(seller);
        unpayableReceiver seller2 = new unpayableReceiver();
        addr6 = address(seller2);
        saleAddr = sale.getSaleAddress();
    }

    function test_listNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        nft.mintAssets(tokenId);
        vm.prank(addr2);
        sale.listNft721(address(nft),address(currency),tokenId,100);
        assertEq(sale.getSeller(address(nft), tokenId),addr2);
    }


    function test_failed_listNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr3);
        nft.mintAssets(tokenId);
        vm.expectRevert(
            abi.encodeWithSelector(Sale.NotOwner.selector, addr4, addr3)
        );
        vm.prank(addr4);
        sale.listNft721(address(nft),address(currency),tokenId,100);
        
    }

    function test_purchaseNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr1);
        currency.mintCoins(10000);
        vm.prank(addr1);
        currency.approve(saleAddr, 10000);
        vm.prank(addr2);
        nft.mintAssets(tokenId);
        vm.prank(addr2);
        nft.approve(saleAddr, tokenId);
        vm.prank(addr2);
        sale.listNft721(address(nft),address(currency),tokenId,100);
        vm.prank(addr1);
        sale.purchaseNft721(address(nft), tokenId);
        assertEq(nft.ownerOf(tokenId),addr1);
    }

    function test_ether_purchaseNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        nft.mintAssets(tokenId);
        vm.prank(addr2);
        nft.approve(saleAddr, tokenId);
        vm.prank(addr2);
        sale.listNft721(address(nft),address(0),tokenId,100);
        vm.deal(addr5,200);
        vm.prank(addr5);
        sale.purchaseNft721{value:100}(address(nft), tokenId);
        assertEq(nft.ownerOf(tokenId),addr5);
    }

    function test_less_ether_purchaseNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        nft.mintAssets(tokenId);
        vm.prank(addr2);
        nft.approve(saleAddr, tokenId);
        vm.prank(addr2);
        sale.listNft721(address(nft),address(0),tokenId,100);
        vm.deal(addr5,50);
        vm.expectRevert(
            abi.encodeWithSelector(Sale.LessEther.selector, 50, 100)
        );
        vm.prank(addr5);
        sale.purchaseNft721{value:50}(address(nft), tokenId);
    }

    function test_failed_ether_purchaseNft721(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr6);
        nft.mintAssets(tokenId);
        vm.prank(addr6);
        nft.approve(saleAddr, tokenId);
        vm.prank(addr6);
        sale.listNft721(address(nft),address(0),tokenId,100);
        vm.deal(addr1,500);
        vm.expectRevert(Sale.EtherNotSent.selector);
        vm.prank(addr1);
        sale.purchaseNft721{value:150}(address(nft), tokenId);
    }
}

contract payableReceiver{
    receive() external payable {}
}

contract unpayableReceiver{
    receive() external payable {
        revert("");
    }
}
