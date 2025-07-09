// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { Token, Currency, Token} from "../src/tokens.sol";
import {Sale} from "../src/nftMarket.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Market is Test {
    Sale public sale;
    Currency public currency;
    Token public token;
    address addr1;
    address addr2;
    address addr3;
    address addr4;
    address addr5;
    address addr6;

    function setUp() public {
        sale = new Sale();
        token = new Token();
        currency = new Currency();
        token = new Token();
        addr1 = address(123);
        addr2 = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp,"200")))));
        addr3 = address(111);
        addr4 = address(1111);
        payableReceiver seller = new payableReceiver();
        addr5 = address(seller);
        unpayableReceiver seller2 = new unpayableReceiver();
        addr6 = address(seller2);
    }

    function test_listNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        token.mintTokens(tokenId);
        vm.prank(addr2);
        sale.listNft1155(address(token),address(currency),tokenId,100);
        assertEq(sale.getSeller(address(token), tokenId),addr2);
    }


    function test_failed_listNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr3);
        token.mintTokens(tokenId);
        vm.expectRevert(Sale.ErrorListing1155.selector);
        vm.prank(addr4);
        sale.listNft1155(address(token),address(currency),tokenId,100);
        
    }

    function test_purchaseNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr1);
        currency.mintCoins(10000);
        vm.prank(addr2);
        token.mintTokens(tokenId);
        vm.prank(addr2);
        sale.listNft1155(address(token),address(currency),tokenId,100);
        uint256 bal1=currency.balanceOf(addr1);
        uint256 bal2=currency.balanceOf(addr2);
        vm.prank(addr1);
        sale.purchaseNft1155(address(token), tokenId);
        uint256 new_bal1=currency.balanceOf(addr1);
        uint256 new_bal2=currency.balanceOf(addr2);
        assertEq(bal1+bal2,new_bal1+new_bal2);
    }

    function test_ether_purchaseNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        token.mintTokens(tokenId);
        vm.prank(addr2);
        sale.listNft1155(address(token),address(0),tokenId,100);
        vm.deal(addr5,200);
        uint256 bal2=address(addr2).balance;
        uint256 bal5=address(addr5).balance;
        vm.prank(addr5);
        sale.purchaseNft1155{value:100}(address(token), tokenId);
        uint256 new_bal2=address(addr2).balance;
        uint256 new_bal5=address(addr5).balance;
        assertEq(bal5+bal2,new_bal5+new_bal2);
    }

    function test_less_ether_purchaseNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr2);
        token.mintTokens(tokenId);
        vm.prank(addr2);
        sale.listNft1155(address(token),address(0),tokenId,100);
        vm.deal(addr5,50);
        vm.expectRevert(
            abi.encodeWithSelector(Sale.LessEther.selector, 50, 100)
        );
        vm.prank(addr5);
        sale.purchaseNft1155{value:50}(address(token), tokenId);
    }

    function test_failed_ether_purchaseNft1155(uint256 tokenId) public {
        vm.assume(tokenId>0 && tokenId<512);
        vm.prank(addr6);
        token.mintTokens(tokenId);
        vm.prank(addr6);
        sale.listNft1155(address(token),address(0),tokenId,100);
        vm.deal(addr1,500);
        vm.expectRevert(Sale.EtherNotSent.selector);
        vm.prank(addr1);
        sale.purchaseNft1155{value:150}(address(token), tokenId);
    }
}

contract payableReceiver is ERC1155Holder  {
    receive() external payable {}

    
}

contract unpayableReceiver is ERC1155Holder  {
    receive() external payable {
        revert("");
    }
}
