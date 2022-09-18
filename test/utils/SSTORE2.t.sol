// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface ISSTORE2 {
    function read(address, uint256) external view returns (bytes memory);
    function read(address, uint256, uint256) external view returns (bytes memory);
    function read(address) external view returns (bytes memory);
    function write(bytes memory) external returns (address);
}

contract SSTORE2Test is Test {
    ISSTORE2 store;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/SSTORE2Wrappers.huff");
        store = ISSTORE2(HuffDeployer.deploy_with_code("utils/SSTORE2", wrapper_code));
    }

    /// @notice Test writing to storage
    function testWriting() public {
        store.write(bytes("hello world"));
    }

}
