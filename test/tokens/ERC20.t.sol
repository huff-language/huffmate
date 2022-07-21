// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface ERC20 {
  /* Metadata */
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /* Accessors */
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  /* EIP-2612 */
  function nonces(address) external view returns (uint256);

  /* Mutators */
  function transfer(address, uint256) external;
  function transferFrom(address, address, uint256) external;
  function approve(address, uint256) external;
  function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external;
  function mint(address, uint256) external;
}

contract ERC20Test is Test {
  ERC20 coin;

  // ERC20 Events
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approve(address indexed owner, address indexed spender, uint256 amount);

  /// @notice Set up the testing suite
  function setUp() public {
    bytes memory name = bytes("coin");
    bytes memory symbol = bytes("COIN");
    console.logString(string.concat("Deploying ERC20 with name, symbol: \"", string(name), "\", \"", string(symbol), "\"..."));
    console.logString(string(name));
    console.logString(string(symbol));

    bytes memory args = bytes.concat(bytes32(name), bytes32(symbol), abi.encode(8));
    coin = ERC20(HuffDeployer.config().with_args(args).deploy("tokens/ERC20Mintable"));
  }

  /// @notice Test name metadata
  function testName() public {
    console.logString("Getting Name...");
    string memory name = coin.name();
    console.logString(name);
    assertEq("coin", name);
  }

  /// @notice Test symbol metadata
  function testSymbol() public {
    assertEq("COIN", coin.symbol());
  }

  /// @notice Test decimals metadata
  function testDecimals() public {
    assertEq(8, coin.decimals());
  }

  /// @notice Test computing the domain separator
  function testDomainSeparator() public {
    // console.logAddress(address(coin));
    // console.logUint(block.chainid);
    // console.logBytes(bytes("1"));
    // console.logBytes32(keccak256("1"));
    // console.logBytes32(keccak256(hex"31"));
    // console.logBytes(bytes("coin"));
    bytes memory encoded = abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("coin")),
        keccak256("1"),
        block.chainid,
        address(coin)
      );
    console.logBytes(encoded);
    bytes32 expected_separator = keccak256(encoded);
    assertEq(expected_separator, coin.DOMAIN_SEPARATOR());
  }

  /// @notice Test approving
  function testApprove(address from, address to, uint256 amount) public {
    // Approve
    vm.startPrank(from);
    // vm.expectEmit(true, true, true, true);
    // emit Approve(from, to, amount);
    coin.approve(to, amount);
    vm.stopPrank();

    // Get Approval
    uint256 allowance = coin.allowance(from, to);
    assertEq(allowance, amount);
  }

  /// @notice Test transferring
  // function testTransfer(address from, address to, uint256 amount) public {
  //   // Approve
  //   vm.startPrank(from);
  //   // vm.expectEmit(true, true, true, true);
  //   // emit Approve(from, to, amount);
  //   coin.transfer(to, amount);
  //   vm.stopPrank();

  //   // Get Approval
  //   uint256 allowance = coin.allowance(from, to);
  //   assertEq(allowance, amount);
  // }

  /// @notice Test mint
  /// @notice Only the owner can mint
  function testMint(address from, address to, uint256 amount) public {
    vm.startPrank(from);
    vm.expectEmit(true, true, true, true);
    emit Transfer(address(0), to, amount);
    coin.mint(to, amount);
    vm.stopPrank();

    // Get Balance
    uint256 balance = coin.balanceOf(from);
    assertEq(balance, amount);
  }
}
