// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Hashmap {
  function loadElement(bytes32) external view returns (bytes32);
  function loadElementFromKeys(bytes32, bytes32) external returns (bytes32);
  function storeElement(bytes32 key, bytes32 value) external;
  function storeElementFromKeys(bytes32 key1, bytes32 key2, bytes32 value) external;
}

contract HashmapTest is Test {
  Hashmap hmap;

  function setUp() public {
    // Create an Instantiable Hashmap
    hmap = Hashmap(HuffDeployer.deploy("data-structures/mocks/InstantiatedHashmap"));
  }

    // bytes memory owner = abi.encode(OWNER);
    // bytes memory authority = abi.encode(INIT_AUTHORITY);
    // bytes.concat(owner, authority);

  /// @notice Test getting a vlue for a key
  function testGetKey(bytes32 key) public {
    bytes32 element = hmap.loadElement(key);
    assertEq(element, bytes32(0));
  }

  /// @notice Test set a key
  function testSetKey(bytes32 key, bytes32 value) public {
    assertEq(hmap.loadElement(key), bytes32(0));
    hmap.storeElement(key, value);
    assertEq(hmap.loadElement(key), value);
  }

  /// @notice Test get with keys
  function testGetKeys(bytes32 key_one, bytes32 key_two) public {
    bytes32 element = hmap.loadElementFromKeys(key_one, key_two);
    assertEq(element, bytes32(0));
  }

  /// @notice Test set with keys
  function testSetKeys(bytes32 key_one, bytes32 key_two, bytes32 value) public {
    assertEq(hmap.loadElementFromKeys(key_one, key_two), bytes32(0));
    hmap.storeElementFromKeys(key_one, key_two, value);
    assertEq(hmap.loadElementFromKeys(key_one, key_two), value);
  }
}
