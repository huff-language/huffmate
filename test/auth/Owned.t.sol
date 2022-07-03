// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Owned {
  function setOwner(address) external;
  function owner() external returns (address);
}

contract OwnedTest is Test {
  Owned owner;
  address constant OWNER = address(0x420);

  event OwnerUpdated(address indexed user, address indexed newOwner);

  function setUp() public {
    bytes memory bytes_owner = abi.encode(OWNER);

    // Create Owner
    vm.expectEmit(true, true, true, true);
    emit OwnerUpdated(address(this), OWNER);
    owner = Owned(
      HuffDeployer.deploy_with_args(
        "auth/Owned",
        bytes_owner
    ));
  }

  /// @notice Test that a non-matching selector reverts
  function testNonMatchingSelector(bytes32 callData) public {
    bytes8[] memory func_selectors = new bytes8[](2);
    func_selectors[0] = bytes8(hex"13af4035");
    func_selectors[1] = bytes8(hex"8da5cb5b");

    bytes8 func_selector = bytes8(callData >> 0xe0);
    for (uint256 i = 0; i < 2; i++) {
      if (func_selector != func_selectors[i]) {
        return;
      }
    }

    address target = address(owner);
    uint256 OneWord = 0x20;
    bool success = false;
    assembly {
      success := staticcall(
          gas(),
          target,
          add(callData, OneWord),
          mload(callData),
          0,
          0
      )
    }
    assert(!success);
  }

  function testGetOwner() public {
    assertEq(OWNER, owner.owner());
  }

  function testSetOwner(address new_owner) public {
    if (new_owner == OWNER) return;
    vm.startPrank(new_owner);
    vm.expectRevert();
    owner.setOwner(new_owner);
    vm.stopPrank();
    assertEq(OWNER, owner.owner());
  }

  function testOwnerCanSetOwner() public {
    address new_owner = address(0x50ca1);
    vm.startPrank(OWNER);
    vm.expectEmit(true, true, true, true);
    emit OwnerUpdated(OWNER, new_owner);
    owner.setOwner(new_owner);
    vm.stopPrank();
    assertEq(new_owner, owner.owner());
  }
}
