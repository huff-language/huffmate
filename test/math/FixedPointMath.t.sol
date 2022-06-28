// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "../lib/HuffTest.sol";

interface IFixedPointMath {
    function mulDivDown(uint256,uint256,uint256) external pure returns(uint256);
    function mulDivUp(uint256,uint256,uint256) external pure returns(uint256);
}

contract FixedPointMathTest is HuffTest {
    IFixedPointMath math;

    constructor() HuffTest("math/FixedPointMath") {}

    function setUp() public {
        /// @notice deploy a new instance of IFixedPointMath by
        /// passing in the address of the deployed Huff contract
        math = IFixedPointMath(deploy());
    }

    function testMulDivDown() public {
        assertEq(math.mulDivDown(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(math.mulDivDown(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(math.mulDivDown(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(math.mulDivDown(369, 271, 1e2), 999);

        assertEq(math.mulDivDown(1e27, 1e27, 2e27), 0.5e27);
        assertEq(math.mulDivDown(1e18, 1e18, 2e18), 0.5e18);
        assertEq(math.mulDivDown(1e8, 1e8, 2e8), 0.5e8);

        assertEq(math.mulDivDown(2e27, 3e27, 2e27), 3e27);
        assertEq(math.mulDivDown(3e18, 2e18, 3e18), 2e18);
        assertEq(math.mulDivDown(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivDownEdgeCases() public {
        assertEq(math.mulDivDown(0, 1e18, 1e18), 0);
        assertEq(math.mulDivDown(1e18, 0, 1e18), 0);
        assertEq(math.mulDivDown(0, 0, 1e18), 0);
    }

    function testFailMulDivDownZeroDenominator() public view {
        math.mulDivDown(1e18, 1e18, 0);
    }

    function testMulDivUp() public {
        assertEq(math.mulDivUp(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(math.mulDivUp(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(math.mulDivUp(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(math.mulDivUp(369, 271, 1e2), 1000);

        assertEq(math.mulDivUp(1e27, 1e27, 2e27), 0.5e27);
        assertEq(math.mulDivUp(1e18, 1e18, 2e18), 0.5e18);
        assertEq(math.mulDivUp(1e8, 1e8, 2e8), 0.5e8);

        assertEq(math.mulDivUp(2e27, 3e27, 2e27), 3e27);
        assertEq(math.mulDivUp(3e18, 2e18, 3e18), 2e18);
        assertEq(math.mulDivUp(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivUpEdgeCases() public {
        assertEq(math.mulDivUp(0, 1e18, 1e18), 0);
        assertEq(math.mulDivUp(1e18, 0, 1e18), 0);
        assertEq(math.mulDivUp(0, 0, 1e18), 0);
    }

    function testFailMulDivUpZeroDenominator() public view {
        math.mulDivUp(1e18, 1e18, 0);
    }

    function testMulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(math.mulDivDown(x, y, denominator), (x * y) / denominator);
    }

    function testFailMulDivDownOverflow(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public view {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            if (denominator == 0 || (x * y) / x == y) revert();
        }

        math.mulDivDown(x, y, denominator);
    }

    function testFailMulDivDownZeroDenominator(uint256 x, uint256 y) public view {
        math.mulDivDown(x, y, 0);
    }

    function testMulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(math.mulDivUp(x, y, denominator), x * y == 0 ? 0 : (x * y - 1) / denominator + 1);
    }

    function testFailMulDivUpOverflow(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public view {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            if (denominator == 0 || (x * y) / x == y) revert();
        }

        math.mulDivUp(x, y, denominator);
    }

    function testFailMulDivUpZeroDenominator(uint256 x, uint256 y) public view {
        math.mulDivUp(x, y, 0);
    }
}
