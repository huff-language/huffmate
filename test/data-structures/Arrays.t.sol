// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IArrays {
    function setArrayFromCalldata(uint256[] calldata) external;

    function loadArray() external view returns (uint256[] memory);
}

contract ArraysTest is Test {
    IArrays arrays;

    uint256[] array = [1, 2, 3, 4, 5];

    function setUp() public {
        // Read instantiable arrays from file
        string memory instantiable_code = vm.readFile(
            "test/data-structures/mocks/ArrayWrappers.huff"
        );

        // Create an Instantiable Arrays
        HuffConfig config = HuffDeployer.config().with_code(instantiable_code);
        arrays = IArrays(config.deploy("data-structures/Arrays"));

        arrays.setArrayFromCalldata(array);
    }

    /// @notice Test setting an array and retrieving it
    function testSetAndLoadArray() public {
        uint256[] memory larray = new uint256[](5);
        larray[0] = 6;
        larray[1] = 7;
        larray[2] = 8;
        larray[3] = 9;
        larray[4] = 10;
        arrays.setArrayFromCalldata(larray);
        bytes32 len = vm.load(address(arrays), bytes32(0));
        bytes32 firstElement = vm.load(address(arrays), keccak256(abi.encode(bytes32(0))));
        bytes32 lastElement = vm.load(address(arrays), bytes32(uint256(keccak256(abi.encode(bytes32(0))))+4));
        assertEq(uint256(len), 5);
        assertEq(uint256(firstElement), 6);
        assertEq(uint256(lastElement), 10);
    }

        /// @notice Test setting an array and retrieving it
    function testGetArray() public {
        uint256[] memory larray = arrays.loadArray();
        assertEq(larray[0], 1);
        assertEq(larray[1], 2);
        assertEq(larray[2], 3);
        assertEq(larray[3], 4);
        assertEq(larray[4], 5);
    }
}
