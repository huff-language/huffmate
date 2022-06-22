// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {HuffTest} from "./utils/HuffTest.sol";

contract OwnableTest is HuffTest("mocks/OwnableMock") {
    Ownable internal ownable;

    function setUp() public {
        ownable = Ownable(deploy());
    }

    function testExample() public {
        vm.prank(alice);
        ownable.setOwner();
        assertEq(alice, ownable.getOwner());
    }
}


address constant alice = address(1);
interface Ownable {
    function setOwner() external;
    function getOwner() external view returns (address);
}