// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface ERC20 {
  /* Metadata */
  function name() external returns (string);
  function symbol() external returns (string);
  function decimals() external returns (uint8);

  /* Accessors */
  function totalSupply() external returns (uint256);
  function balanceOf(address) external returns (uint256);
  function allowance(address, address) external returns (uint256);

  /* EIP-2612 */
  function nonces(address) external returns (uint256);

  /* Mutators */
  function transfer(address, uint256) external;
  function transferFrom(address, address, uint256) external;
  function approve(address, uint256) external;
  function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external;
}

contract ERC20Test is Test {
  ERC20 buttcoin;

  // ERC20 Events
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approve(address indexed owner, address indexed spender, uint256 amount);

  function setUp() public {
    erc20 = Hashmap(HuffDeployer.deploy("data-structures/mocks/InstantiatedHashmap"));
  }

  /// @notice Test getting a vlue for a key
  function testGetKey(bytes32 key) public {
    bytes32 element = hmap.loadElement(key);
    assertEq(element, bytes32(0));
  }

}