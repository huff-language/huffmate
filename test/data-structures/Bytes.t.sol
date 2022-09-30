// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IBytes {
    function concatMemoryAndSet() external;
    
    function getStorage(bytes32) external view returns (bytes32);
}

contract BytesTest is Test {
    IBytes b;
    
    function setUp() public {
        emit log("set");
        string memory instantiable_code = vm.readFile(
            "test/data-structures/mocks/InstantiatedBytes.huff"
        );

        // Create an Instantiable Arrays
        HuffConfig config = HuffDeployer.config().with_code(instantiable_code);
        b = IBytes(config.deploy("data-structures/Bytes"));
    }
    
    function testConcat() public {
        b.concatMemoryAndSet();
        
        assertEq(b.getStorage(bytes32(0)), bytes32(uint256(64)));
        assertEq(b.getStorage(bytes32(uint256(32))), bytes32(0xbabe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe1babe));
        assertEq(b.getStorage(bytes32(uint256(64))), bytes32(0xbabe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe2babe));
    }
}