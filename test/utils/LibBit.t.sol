// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface ILibBit {
	function lsb(uint256) external pure returns (uint256);
	function msb(uint256) external pure returns (uint256);
	function popCount(uint256) external pure returns (uint256);
}

contract LibBitTest is Test {
    ILibBit public lib;

    function setUp() public {
        /// @notice deploy a new instance of IJumpTableUtil by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/LibBitWrappers.huff");
        lib = ILibBit(HuffDeployer.deploy_with_code("utils/LibBit", wrapper_code));
    }

    function testFuzzMSB() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(lib.msb((1 << i) - 1), i - 1);
            assertEq(lib.msb((1 << i)), i);
            assertEq(lib.msb((1 << i) + 1), i);
        }
        assertEq(lib.msb(0), 256);
    }

    function testMSB() public {
        assertEq(lib.msb(0xff << 3), 10);
    }

    function testFuzzLSB() public {
        uint256 brutalizer = uint256(keccak256(abi.encode(address(this), block.timestamp)));
        for (uint256 i = 0; i < 256; i++) {
            assertEq(lib.lsb(1 << i), i);
            assertEq(lib.lsb(type(uint256).max << i), i);
            assertEq(lib.lsb((brutalizer | 1) << i), i);
        }
        assertEq(lib.lsb(0), 256);
    }

    function testLSB() public {
        assertEq(lib.lsb(0xff << 3), 3);
    }

    function testFuzzPopCount(uint256 x) public {
        uint256 c;
        unchecked {
            for (uint256 t = x; t != 0; c++) {
                t &= t - 1;
            }
        }
        assertEq(lib.popCount(x), c);
    }

    function testPopCount() public {
        assertEq(lib.popCount((1 << 255) | 1), 2);
    }
}
