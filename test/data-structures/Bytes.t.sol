// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IBytes {
    function concatMemoryAndSet1() external;
    function concatMemoryAndSet2() external;
    function concatMemoryAndSet3() external;
    function concatMemoryAndSet4() external;
    function concatMemoryAndSet5() external;
    function concatMemoryAndSet6() external;
    function sliceMemoryAndSet1() external;
    function sliceMemoryAndSet2() external;
    function sliceMemoryAndSet3() external;
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
    
    function testConcat4() public {
        b.concatMemoryAndSet4();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(37)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(0xbabe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(bytes5(0xbabe2babe2)));
    }
    
    function testConcat5() public {
        b.concatMemoryAndSet5();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(15)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(bytes15(0xbabe1babe1babe1babe1babe2babe2)));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(0));
    }
    
    function testConcat6() public {
        b.concatMemoryAndSet6();
        
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(15)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(bytes15(0xbabe1babe1babe1babe1babe2babe2)));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(0));
    }
    
    function testSlice1() public {
        b.sliceMemoryAndSet1();
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(16)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(bytes16(0xbabe1babe1babe1babe1babe1babe1ba)));
    }
    
    function testSlice2() public {
        b.sliceMemoryAndSet2();
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(36)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(0x1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babebabe));
        assertEq(vm.load(address(b), bytes32(uint256(64))), bytes32(bytes4(0x2babe2ba)));
    }
    
    function testSlice3() public {
        b.sliceMemoryAndSet3();
        assertEq(vm.load(address(b), bytes32(0)), bytes32(uint256(4)));
        assertEq(vm.load(address(b), bytes32(uint256(32))), bytes32(bytes4(0xbabe2bab)));
    }
}