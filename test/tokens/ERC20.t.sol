// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface ERC20 {
  /* Metadata */
  function name() external returns (string memory);
  function symbol() external returns (string memory);
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
  ERC20 coin;

  // ERC20 Events
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approve(address indexed owner, address indexed spender, uint256 amount);

  /// @notice Set up the testing suite
  function setUp() public {
    coin = ERC20(
      HuffDeployer.deploy_with_args(
        "tokens/ERC20",
        bytes.concat(bytes("coin"), bytes("COIN"), abi.encode(8))
      )
    );
  }

  /// @notice Test name metadata
  function testName() public {
    assertEq("coin", coin.name());
  }

  /// @notice Test symbol metadata
  function testSymbol() public {
    assertEq("COIN", coin.symbol());
  }

  /// @notice Test decimals metadata
  function testDecimals() public {
    assertEq(20, coin.decimals());
  }

}