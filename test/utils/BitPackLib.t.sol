// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface IBitPackLib {
    function packValue(bytes32, uint256, uint256, uint256) external pure returns (bytes32);
    function unpackValueFromRight(bytes32, uint256) external pure returns (uint256);
    function unpackValueFromLeft(bytes32, uint256) external pure returns (uint256);
    function unpackValueFromCenter(bytes32, uint256, uint256) external pure returns (uint256);
}

contract BitPackLibTest is Test {
    IBitPackLib bitPackLib;

    function setUp() public {
        /// @notice deploy a new instance of IBitPackLib by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/BitPackLibWrappers.huff");
        bitPackLib = IBitPackLib(HuffDeployer.deploy_with_code("utils/BitPackLib", wrapper_code));
    }

    function testPackValue() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x696969, 8, 24);
        assertEq(newWord, bytes32(0x0069696900000000000000000000000000000000000000000000000000000000));
    }

    function testPackLargeValue() public {
        // Adds two 0's as right padding
        // 256 - 248 = 8 bits = 1 byte = 2 hex characters
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x69696969696969696969696969696969696969696969696969696969696969, 0, 248);
        assertEq(newWord, bytes32(0x6969696969696969696969696969696969696969696969696969696969696900));
    }

    function testPackHighIndex() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x69, 256, 0);
        assertEq(newWord, bytes32(0x0000000000000000000000000000000000000000000000000000000000000069));
    }


    function testPackHighSize() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x69, 0, 256);
        assertEq(newWord, bytes32(0x0000000000000000000000000000000000000000000000000000000000000069));
    }

    function testUnpackValueFromRight() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x2323696969, 232, 24);
        uint256 value = bitPackLib.unpackValueFromRight(newWord, 24);
        assertEq(value, 0x696969);
    }

    function testUnpackValueFromLeft() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x696969, 0, 24);
        uint256 value = bitPackLib.unpackValueFromLeft(newWord, 24);
        assertEq(value, 0x696969);
    }

    function testUnpackValueFromCenter() public {
        bytes32 newWord = bitPackLib.packValue(bytes32(0), 0x696969, 64, 24);
        uint256 value = bitPackLib.unpackValueFromCenter(newWord, 64, 24);
        assertEq(value, 0x696969);
    }
}