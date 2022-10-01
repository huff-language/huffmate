// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IBytes {
    function concatMemoryAndSet1() external;
    function concatMemoryAndSet2() external;
    function concatMemoryAndSet3() external;
}

contract BytesTest is Test {
    IBytes b;
    
    function setUp() public {
        string memory instantiable_code = vm.readFile(
            "test/data-structures/mocks/BytesWrappers.huff"
        );

        // Create an Instantiable Arrays
        HuffConfig config = HuffDeployer.config().with_code(instantiable_code);
        b = IBytes(config.deploy("data-structures/Bytes"));
    }
    
    function testConcat1() public {
        b.concatMemoryAndSet1();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(64)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(0xbabe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(0xbabe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe));
    }

    function testConcat2() public {
        b.concatMemoryAndSet2();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(96)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(0xbabe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(0xbabe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe));
        assertEq(vm.load(address(b), bytes32(uint256(96))), bytes32(0xbabe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe));
    }

    function testConcat3() public {
        b.concatMemoryAndSet3();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(32)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(0xbabe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(0));
    }
}