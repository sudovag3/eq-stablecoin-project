// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {Test} from "forge-std/Test.sol";
import {EQuicoin} from "../src/EQuicoin.sol";
import "../src/SafeMath.sol";

contract EQuicoinTest is Test {
    using SafeMath for uint256;
    EQuicoin equicoin;
    address user = makeAddr("user");
    address spender = makeAddr("spender");
    address other = makeAddr("other");
    address newOwner = makeAddr("newOwner");

    function setUp() external {
        vm.prank(user);
        equicoin = new EQuicoin(100000000000000000, "EQ", "EQI", 6);
    }

    function testDivByZero() public {
        vm.prank(user);
        vm.expectRevert();
        uint256 a = 5;
        a.div(0);
    }

    function testSubWithGreaterValue() public {
        vm.prank(user);
        vm.expectRevert();
        uint256 a = 5;
        a.sub(6);
    }

    function testAddWithOverflow() public {
        vm.prank(user);
        uint256 max = type(uint256).max;
        vm.expectRevert();
        max.add(1);
    }

    // Ownable Tests
    function testOwnerOnInitialization() public {
        vm.prank(user);
        assertEq(equicoin.owner(), user);
    }

    function testOnlyOwnerModifier() public {
        vm.prank(other);
        vm.expectRevert();
        equicoin.transferOwnership(other);
    }

    function testTransferOwnership() public {
        vm.prank(user);
        equicoin.transferOwnership(newOwner);
        assertEq(equicoin.owner(), newOwner);
    }

    // BasicToken Tests
    function testTransferTokens() public {
        vm.prank(user);
        uint256 initialBalance = 1000;
        equicoin.transfer(spender, initialBalance);
        assertEq(equicoin.balanceOf(spender), initialBalance);
    }

    function testBalanceOf() public {
        uint256 balance = equicoin.balanceOf(newOwner);
        assertEq(balance, 0);
    }

    // StandardToken Tests
    function testTransferFrom() public {
        vm.prank(user);
        uint256 initialBalance = 1000;
        equicoin.approve(spender, initialBalance);
        vm.prank(spender);
        equicoin.transferFrom(user, other, initialBalance);
        assertEq(equicoin.balanceOf(other), initialBalance);
    }

    function testApprove() public {
        vm.prank(user);
        uint256 amount = 500;
        equicoin.approve(spender, amount);
        assertEq(equicoin.allowance(user, spender), amount);
    }

    function testAllowance() public {
        vm.prank(user);
        uint256 allowed = equicoin.allowance(user, other);
        assertEq(allowed, 0);
    }

    //
    // BLACKLIST
    //

    function testAddToBlackList() public {
        vm.prank(user);
        equicoin.addBlackList(other);
        assert(equicoin.getBlackListStatus(other));
    }

    function testRemoveFromBlackList() public {
        vm.prank(user);
        equicoin.addBlackList(other);
        vm.prank(user);
        equicoin.removeBlackList(other);
        assert(!equicoin.getBlackListStatus(other));
    }

    function testDestroyBlackFunds() public {
        vm.prank(user);
        equicoin.transfer(other, 1000);

        vm.prank(user);
        equicoin.addBlackList(other);

        vm.prank(user);
        equicoin.destroyBlackFunds(other);
        assertEq(equicoin.balanceOf(other), 0);
    }

    function testTransferFromBlackListed() public {
        vm.prank(user);
        equicoin.removeBlackList(other);
        vm.prank(user);
        equicoin.transfer(other, 1000);
        vm.prank(user);
        equicoin.addBlackList(other);
        vm.prank(other);
        equicoin.approve(spender, 1000);
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(other, spender, 500);
    }

    function testTransferBlackListed() public {
        vm.prank(user);
        equicoin.removeBlackList(other);
        vm.prank(user);
        equicoin.transfer(other, 1000);
        vm.prank(user);
        equicoin.addBlackList(spender);

        vm.expectRevert();
        vm.prank(spender);
        equicoin.transfer(spender, 500);
    }

    function testOnlyOwnerCanAddToBlackList() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.addBlackList(other);
    }

    function testOnlyOwnerCanRemoveFromBlackList() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.removeBlackList(other);
    }

    function testOnlyOwnerCanDestroyBlackFunds() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.destroyBlackFunds(other);
    }

    //
    // Pausable
    //

    function testPauseContract() public {
        vm.prank(user);
        equicoin.pause();
        assert(equicoin.paused());
    }

    function testUnpauseContract() public {
        vm.prank(user);
        equicoin.pause();
        vm.prank(user);
        equicoin.unpause();
        assert(!equicoin.paused());
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.pause();
    }

    function testOnlyOwnerCanUnpause() public {
        vm.prank(user);
        equicoin.pause();
        vm.prank(spender);
        vm.expectRevert();
        equicoin.unpause();
    }

    function testTransferWhenPaused() public {
        vm.prank(user);
        equicoin.pause();
        vm.prank(user);
        vm.expectRevert();
        equicoin.transfer(spender, 100);
    }

    function testTransferFromWhenPaused() public {
        vm.prank(user);
        equicoin.approve(spender, 1000);
        vm.prank(user);
        equicoin.pause();
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(user, other, 500);
    }

    function testTransferWhenNotPaused() public {
        vm.prank(user);
        equicoin.transfer(spender, 100);
        assertEq(equicoin.balanceOf(spender), 100);
    }

    function testTransferFromWhenNotPaused() public {
        vm.prank(user);
        equicoin.approve(spender, 1000);
        vm.prank(spender);
        equicoin.transferFrom(user, other, 500);
        assertEq(equicoin.balanceOf(other), 500);
    }

    //
    // EQuicoin
    //

    function testDeprecate() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        assert(equicoin.deprecated());
        assertEq(equicoin.upgradedAddress(), dummyUpgradedAddress);
    }

    function testTotalSupplyWhenDeprecated() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        vm.prank(user);
        equicoin.totalSupply();
    }

    function testTransferWhenDeprecated() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        vm.prank(user);
        equicoin.transfer(spender, 100);
    }

    function testTransferFromWhenDeprecated() public {
        vm.prank(user);
        equicoin.approve(spender, 1000);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        vm.prank(user);
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        vm.prank(spender);
        equicoin.transferFrom(user, other, 500);
    }

    function testIssueTokens() public {
        vm.prank(user);
        uint256 initialSupply = equicoin.totalSupply();
        uint256 initialBalance = equicoin.balanceOf(user);
        vm.prank(user);
        equicoin.issue(1000);
        assertEq(equicoin.totalSupply(), initialSupply + 1000);
        assertEq(equicoin.balanceOf(user), initialBalance + 1000);
    }

    function testRedeemTokens() public {
        vm.prank(user);
        uint256 initialSupply = equicoin.totalSupply();
        uint256 initialBalance = equicoin.balanceOf(user);
        vm.prank(user);
        equicoin.redeem(1000);
        assertEq(equicoin.totalSupply(), initialSupply - 1000);
        assertEq(equicoin.balanceOf(user), initialBalance - 1000);
    }

    function testSetParams() public {
        vm.prank(user);
        equicoin.setParams(10, 40);
        assertEq(equicoin.basisPointsRate(), 10);
        assertEq(equicoin.maximumFee(), 40 * (10 ** equicoin.decimals()));
    }

    function testBalanceOfWhenDeprecated() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        equicoin.balanceOf(user);
    }

    function testApproveWhenDeprecated() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        equicoin.approve(spender, 1000);
    }

    function testAllowanceWhenDeprecated() public {
        vm.prank(user);
        address dummyUpgradedAddress = makeAddr("dummyUpgraded");
        equicoin.deprecate(dummyUpgradedAddress);
        vm.expectRevert();
        equicoin.allowance(user, spender);
    }

    function testOnlyOwnerCanDeprecate() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.deprecate(makeAddr("dummyUpgraded"));
    }

    function testOnlyOwnerCanIssue() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.issue(1000);
    }

    function testOnlyOwnerCanRedeem() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.redeem(1000);
    }

    function testOnlyOwnerCanSetParams() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.setParams(10, 40);
    }

    function testTransferToContractAddress() public {
        vm.prank(user);
        vm.expectRevert();
        equicoin.transfer(address(equicoin), 100);
    }

    function testTransferWithNoBalance() public {
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transfer(other, 100);
    }

    function testTransferWithMaximumFee() public {
        vm.prank(user);
        uint256 initialBalance = equicoin.balanceOf(user);
        vm.prank(user);
        equicoin.setParams(19, 49); // Setting fee
        vm.prank(user);
        equicoin.transfer(spender, 1000); // This should trigger maximum fee
        assertEq(equicoin.balanceOf(user), initialBalance - 1000 + 1);
        assertEq(equicoin.balanceOf(spender), 999); // 1 taken as fee
    }

    function testTransferFromWithMaximumFee() public {
        vm.prank(user);
        equicoin.approve(spender, 100000000);
        uint256 initialBalance = equicoin.balanceOf(user);
        vm.prank(user);
        equicoin.setParams(19, 49); // Setting fee
        uint256 expectedFee = equicoin.calcFee(100000000);
        vm.prank(spender);
        equicoin.transferFrom(user, other, 100000000); // This should trigger maximum fee
        assertEq(
            equicoin.balanceOf(user),
            initialBalance - 100000000 + expectedFee
        );
        assertEq(equicoin.balanceOf(other), 100000000 - expectedFee); // 49 taken as fee
    }

    function testGetOwner() public {
        assertEq(equicoin.getOwner(), user);
    }

    function testDeprecateWithSameAddress() public {
        vm.prank(user);
        equicoin.deprecate(address(other));

        vm.expectRevert();
        vm.prank(user);
        equicoin.deprecate(address(other));
    }

    function testIssueInvalidAmount() public {
        vm.expectRevert();
        vm.prank(user);
        equicoin.issue(0);
    }

    function testRedeemInvalidAmount() public {
        uint256 initialSupply = equicoin.totalSupply();
        vm.expectRevert();
        vm.prank(user);
        equicoin.redeem(initialSupply + 1); // Redeeming more than total supply
    }

    function testSetParamsInvalidValues() public {
        vm.prank(user);
        vm.expectRevert();
        equicoin.setParams(20, 50); // Invalid values
    }

    //
    // Decr/Incr ease allowance
    function testIncreaseApproval() public {
        vm.prank(user);
        equicoin.approve(spender, 500);
        vm.prank(user);
        equicoin.increaseApproval(spender, 300);
        assertEq(equicoin.allowance(user, spender), 800);
    }

    function testDecreaseApprovalLessThanCurrent() public {
        vm.prank(user);
        equicoin.approve(spender, 500);
        vm.prank(user);
        equicoin.decreaseApproval(spender, 300);
        assertEq(equicoin.allowance(user, spender), 200);
    }

    function testDecreaseApprovalMoreThanCurrent() public {
        vm.prank(user);
        equicoin.approve(spender, 500);
        vm.prank(user);
        equicoin.decreaseApproval(spender, 600);
        assertEq(equicoin.allowance(user, spender), 0);
    }

    function testTransferFromToContractAddress() public {
        vm.prank(user);
        equicoin.approve(spender, 1000);
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(user, address(equicoin), 500);
    }

    function testTransferFromToZeroAddress() public {
        vm.prank(user);
        equicoin.approve(spender, 1000);
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(user, address(0), 500);
    }

    function testTransferFromMoreThanBalance() public {
        vm.prank(user);
        equicoin.approve(spender, 1000000000000000000); // Approving more than user's balance
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(user, other, 1000000000000000000); // Trying to transfer more than user's balance
    }

    function testTransferFromMoreThanAllowance() public {
        vm.prank(user);
        equicoin.approve(spender, 500); // Approving 500 tokens
        vm.prank(spender);
        vm.expectRevert();
        equicoin.transferFrom(user, other, 1000); // Trying to transfer 1000 tokens
    }
}
