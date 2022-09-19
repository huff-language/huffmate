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

    /// @notice Test sstore2 readAt
    function testReadAt() public {
        bytes memory input = bytes("this string is longer than 32 bytes and will require multiple words to store");
        bytes memory expectedCodePacked = abi.encodePacked(
            hex"00697320737472696e67206973206c6f6e676572207468616e20333220627974657320616e642077696c6c2072657175697265206d756c7469706c6520776f72647320746f2073746f7265"
        );

        // Store "hello world"
        address pointer = store.write(input);
        assert(pointer != address(0));
        assertEq(abi.encodePacked(hex"00", input), pointer.code);

        // Try to read back from the pointer
        bytes memory result = store.read(pointer, 0x03);
        bytes memory packedResult = abi.encodePacked(hex"00", result);
        assertEq(packedResult, expectedCodePacked);
    }

    /// @notice Test sstore2 readBetween
    function testReadBetween() public {
        bytes memory input = bytes("this string is longer than 32 bytes and will require multiple words to store");
        bytes memory expectedCodePacked = abi.encodePacked(hex"0074686973");

        // Store "hello world"
        address pointer = store.write(input);
        assert(pointer != address(0));
        assertEq(abi.encodePacked(hex"00", input), pointer.code);

        // Try to read back from the pointer
        bytes memory result = store.read(pointer, 0x01, 0x05);
        bytes memory packedResult = abi.encodePacked(hex"00", result);
        assertEq(packedResult, expectedCodePacked);
    }
}
