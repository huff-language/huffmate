// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IArrays {
    function setArrayFromCalldata(uint256[] calldata) external;

    function loadArray() external view returns (uint256[] memory);
}

contract ArraysTest is Test {
    IArrays arrays;

    function setUp() public {
        // Read instantiable arrays from file
        string memory instantiable_code = vm.readFile(
            "test/data-structures/mocks/InstantiatedArrays.huff"
        );

        // Create an Instantiable Arrays
        HuffConfig config = HuffDeployer.config().with_code(instantiable_code);
        arrays = IArrays(config.deploy("data-structures/Arrays"));
    }

    /// @notice Test setting an array and retrieving it
    function testSetAndLoadArray() public {
        uint256[] memory array = new uint256[](5);
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;
        array[3] = 4;
        array[4] = 5;
        arrays.setArrayFromCalldata(array);
        //assertEq(arrays.loadArray(), array);
    }
}
