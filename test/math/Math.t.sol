// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Math {
    function sqrt(uint256) external pure returns (uint256);
    function max(uint256,uint256) external pure returns (uint256);
    function min(uint256,uint256) external pure returns (uint256);
    function average(uint256,uint256) external pure returns (uint256);
}

contract MathTest is Test {
    Math math;

    function setUp() public {
        math = Math(HuffDeployer.deploy("math/Math"));
    }

    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function testSqrt() public {
       uint256 result = math.sqrt(69); 
       assertEq(result, 8);
    }

    // function testSqrt(uint16 num) public {
    //     uint256 result = math.sqrt(num);
    //     assertEq(result, sqrt(num));
    // }

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
}