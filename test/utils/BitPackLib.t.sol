// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IBitPackLib {
    function packValue(bytes32, uint256, uint256, uint256) external pure returns (bytes32);
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
}