// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface ISSTORE2 {
    function read(address, uint256) external returns (bytes memory);
    function read(address, uint256, uint256) external returns (bytes memory);
    function read(address) external returns (bytes memory);
    function write(bytes memory) external returns (address);
}

contract SSTORE2Test is Test {
    ISSTORE2 store;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/SSTORE2Wrappers.huff");
        store = ISSTORE2(HuffDeployer.deploy_with_code("utils/SSTORE2", wrapper_code));
    }

    /// @notice Test writing and reading from storage with sstore2
    function testSmallWriteRead() public {
        bytes memory input = bytes("hello world");
        bytes memory expectedCodePacked = abi.encodePacked(
            hex"00",
            input
        );

        // Store "hello world"
        address pointer = store.write(input);
        assert(pointer != address(0));
        assertEq(expectedCodePacked, pointer.code);

        // Try to read back from the pointer
        bytes memory result = store.read(pointer);
        bytes memory packedResult = abi.encodePacked(
            hex"00",
            result
        );
        assertEq(packedResult, expectedCodePacked);
        assertEq(packedResult, pointer.code);
    }

    /// @notice Test writing and reading from storage with sstore2
    function testMultiWordWriteRead() public {
        bytes memory input = bytes("this string is longer than 32 bytes and will require multiple words to store");
        bytes memory expectedCodePacked = abi.encodePacked(
            hex"00",
            input
        );

        // Store "hello world"
        address pointer = store.write(input);
        assert(pointer != address(0));
        assertEq(expectedCodePacked, pointer.code);

        // Try to read back from the pointer
        bytes memory result = store.read(pointer);
        bytes memory packedResult = abi.encodePacked(
            hex"00",
            result
        );
        assertEq(packedResult, expectedCodePacked);
        assertEq(packedResult, pointer.code);
    }
}
