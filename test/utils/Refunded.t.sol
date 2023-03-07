// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IRefundedMock {
    function refundedCall() external payable;
    function nonRefundedCall() external payable;
}

contract RefundedTest is Test {
    IRefundedMock refunded;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/RefundedWrappers.huff");
        refunded = IRefundedMock(HuffDeployer.deploy_with_code("utils/Refunded", wrapper_code));
    }

    function testRefundedCall() public {
        // Deal some balances
        vm.deal(address(this), 100 ether);
        vm.deal(address(refunded), 100 ether);

        // Record the initial balances
        uint256 balance = address(this).balance;
        uint256 refundedBalance = address(refunded).balance;

        // Call the refunded function
        refunded.refundedCall();

        // We should have gotten a refund
        // assertApproxEqAbs(address(this).balance, balance, 1_000_000);
        // assertTrue(address(refunded).balance < refundedBalance);
    }

    function testRefundedNonCall() public {
        // Deal some balances
        vm.deal(address(this), 100 ether);
        vm.deal(address(refunded), 100 ether);

        // Record the initial balances
        uint256 balance = address(this).balance;
        uint256 refundedBalance = address(refunded).balance;

        // Call the non refunded function
        refunded.nonRefundedCall();

        // Balances should be the same
        assertEq(address(this).balance, balance);
        assertEq(address(refunded).balance, refundedBalance);
    }
}