// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface ICalls {
    // function simpleCall(address, uint256, uint256, uint256, uint256) external payable returns (bool, bytes memory);
    function simpleCall(address) external payable returns (bool);

    function delegateCall(address, uint256, uint256, uint256, uint256) external payable returns (bool, bytes memory);

    function tst(uint256) external;

    function call(address) external payable returns (bool);
}

contract Dummy is Test {
    bool public triggered;
    uint256 public withVal;

    function get(uint256 val) external pure returns (uint256) {
        return val;
    }

    fallback() external payable {
        triggered = true;
        withVal = msg.value;
    }
}

contract CallsTest is Test {
    ICalls calls;
    Dummy dummy;

    function setUp() public {
        calls = ICalls(HuffDeployer.deploy("utils/Calls"));
        dummy = new Dummy();
    }

    function testSimpleCall() public {
        // calls.simpleCall(address(dummy), 0, 0, 0, 0);
        bool success = calls.simpleCall(address(dummy));
        assertTrue(success);
        assertTrue(dummy.triggered());
        assertEq(dummy.withVal(), 0);
    }
}