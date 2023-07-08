// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface ILibBit {
    function ffs(uint256) external pure returns (uint256);
    function fls(uint256) external pure returns (uint256);
    function popCount(uint256) external pure returns (uint256);
    function isPowOf2(uint256) external pure returns (uint256);
}

contract LibBitTest is Test {
    ILibBit public lib;

    function setUp() public {
        /// @notice deploy a new instance of IJumpTableUtil by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/LibBitWrappers.huff");
        lib = ILibBit(HuffDeployer.deploy_with_code("utils/LibBit", wrapper_code));
    }

    function testFuzzFLS() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(lib.fls((1 << i) - 1), i - 1);
            assertEq(lib.fls((1 << i)), i);
            assertEq(lib.fls((1 << i) + 1), i);
        }
        assertEq(lib.fls(0), 256);
    }

    function testFLS() public {
        assertEq(lib.fls(0xff << 3), 10);
    }

    function testFuzzFFS() public {
        uint256 brutalizer = uint256(keccak256(abi.encode(address(this), block.timestamp)));
        for (uint256 i = 0; i < 256; i++) {
            assertEq(lib.ffs(1 << i), i);
            assertEq(lib.ffs(type(uint256).max << i), i);
            assertEq(lib.ffs((brutalizer | 1) << i), i);
        }
        assertEq(lib.ffs(0), 256);
    }

    function testFFS() public {
        assertEq(lib.ffs(0xff << 3), 3);
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

    function testIsPowOf2() public {
        assertEq(lib.isPowOf2(0), 0);
        assertEq(lib.isPowOf2(type(uint256).max), 0);
        unchecked {
            for (uint256 i; i < 256; ++i) {
                uint256 x = 1 << i;
                assertEq(lib.isPowOf2(x), 1);
                assertEq(lib.isPowOf2(~x), 0);
            }
        }
    }

    function testFuzzIsPowOf2(uint256 x) public {
        vm.assume(x > 0 && x < type(uint256).max);
        uint256 result;
        assembly {
            result := iszero(add(and(x, sub(x, 1)), iszero(x)))
        }
        assertEq(lib.isPowOf2(x), result);
    }
}
