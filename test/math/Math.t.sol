// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Math {
    function sqrt(uint256) external pure returns (uint256);
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
}