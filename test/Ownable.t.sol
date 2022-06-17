// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HuffTester} from "./utils/HuffTester.sol";

interface Ownable {
    function setOwner() external;
    function getOwner() external view returns (address);
}

address constant alice = address(1);

contract OwnableTest is HuffTester {
    Ownable internal ownable;
    

    function setUp() public {
        ownable = Ownable(deploy("src/mocks/OwnableMock.huff"));
    }

    function testExample() public {
        vm.prank(alice);
        ownable.setOwner();
        assertEq(alice, ownable.getOwner());
    }
}
