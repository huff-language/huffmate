// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Math {
    function sqrt(uint256) external pure returns (uint256);
    function max(uint256,uint256) external pure returns (uint256);
    function min(uint256,uint256) external pure returns (uint256);
    function average(uint256,uint256) external pure returns (uint256);
    function ceilDiv(uint256,uint256) external pure returns (uint256);
}

contract MathTest is Test {
    Math math;

    function setUp() public {
        string memory wrappers = vm.readFile("test/math/mocks/MathWrappers.huff");
        math = Math(HuffDeployer.deploy_with_code("math/Math", wrappers));
    }

    // Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/e7397844f8dd9b54fb4227b91b20f3bd2e82dab2/contracts/utils/math/Math.sol#L158
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return result < a / result ? result : a / result;
        }
    }

    function testSqrt() public {
        uint256 result = math.sqrt(69);
        assertEq(result, 8);
    }

    function testSqrt(uint256 num) public {
        uint256 result = math.sqrt(num);
        assertEq(result, sqrt(num));
    }

    function testMax() public {
        uint256 result = math.max(420, 69);
        assertEq(result, 420);
    }

    function testMax(uint256 a, uint256 b) public {
        uint256 result = math.max(a, b);

        if (a > b) {
            assertEq(result, a);
        }
        if (b > a) {
            assertEq(result, b);
        }
    }

    function testMin() public {
        uint256 result = math.min(420, 69);
        assertEq(result, 69);
    }

    function testMin(uint256 a, uint256 b) public {
        uint256 result = math.min(a, b);

        if (a < b) {
            assertEq(result, a);
        }
        if (b < a) {
            assertEq(result, b);
        }
    }

    // Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/e7397844f8dd9b54fb4227b91b20f3bd2e82dab2/contracts/utils/math/Math.sol#L34
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function testAverage() public {
        uint256 result = math.average(10, 30);
        assertEq(result, 20);
    }

    function testAverage(uint256 a, uint256 b) public {
        uint256 result = math.average(a, b);
        assertEq(result, average(a, b));
    }

    // Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/e7397844f8dd9b54fb4227b91b20f3bd2e82dab2/contracts/utils/math/Math.sol#L45
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function testCeilDiv() public {
        uint256 result = math.ceilDiv(420, 69);
        assertEq(result, 7);
    }

    function testCeilDiv(uint256 a, uint256 b) public {
        if (b == 0) return;
        uint256 result = math.ceilDiv(a, b);
        assertEq(result, ceilDiv(a, b));
    }
}