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
