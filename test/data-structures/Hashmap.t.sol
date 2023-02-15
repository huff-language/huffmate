// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface Hashmap {
  function loadElement(bytes32) external view returns (bytes32);
  function loadElementFromKeys(bytes32, bytes32) external returns (bytes32);
  function loadElementFromKeys2D(bytes32, bytes32, bytes32) external returns (bytes32);
  function loadElementFromKeys3D(bytes32, bytes32, bytes32, bytes32) external returns (bytes32);
  function storeElement(bytes32 key, bytes32 value) external;
  function storeElementFromKeys(bytes32 key1, bytes32 key2, bytes32 value) external;
  function storeElementFromKeys2D(
    bytes32 slot,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external;
  function storeElementFromKeys3D(
    bytes32 slot,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external;
}

contract HashmapTest is Test {
  Hashmap hmap;

  function setUp() public {
    // Read instantiable hashmap from file
    string memory instantiable_code = vm.readFile("test/data-structures/mocks/HashmapWrappers.huff");

    // Create an Instantiable Hashmap
    HuffConfig config = HuffDeployer.config().with_code(instantiable_code);
    hmap = Hashmap(config.deploy("data-structures/Hashmap"));
  }

  /// @notice Test getting a value for a key
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

  /// @notice Test set with slot and 2 keys
  function testSetKeys2D(
    bytes32 slot, 
    bytes32 key_one, 
    bytes32 key_two, 
    bytes32 value
  ) public {
    assertEq(hmap.loadElementFromKeys2D(slot, key_one, key_two), bytes32(0));
    hmap.storeElementFromKeys2D(slot, key_one, key_two, value);
    assertEq(hmap.loadElementFromKeys2D(slot, key_one, key_two), value);
  }

  /// @notice Test set with slot and 3 keys
  function testSetKeys3D(
    bytes32 slot, 
    bytes32 key_one, 
    bytes32 key_two,
    bytes32 key_three, 
    bytes32 value
  ) public {
    assertEq(hmap.loadElementFromKeys3D(slot, key_one, key_two, key_three), bytes32(0));
    hmap.storeElementFromKeys3D(slot, key_one, key_two, key_three, value);
    assertEq(hmap.loadElementFromKeys3D(slot, key_one, key_two, key_three), value);
  }
}
