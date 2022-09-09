// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// adapter from: https://github.com/transmissions11/solmate/blob/main/src/test/utils/DSTestPlus.sol
abstract contract FuzzingUtils {
    function min3(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return a > b ? (b > c ? c : b) : (a > c ? c : a);
    }

    function min2(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }
}