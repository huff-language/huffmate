// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {NonMatchingSelectorsHelper} from "../test-utils/NonMatchingSelectorHelper.sol";


interface Owned {
  function setOwner(address) external;
  function owner() external returns (address);
}

contract OwnedTest is Test, NonMatchingSelectorsHelper {
  Owned owner;
  address constant OWNER = address(0x420);

  event OwnerUpdated(address indexed user, address indexed newOwner);

  function setUp() public {
    // Create Owner
    string memory wrapper_code = vm.readFile("test/auth/mocks/OwnedWrappers.huff");
    HuffConfig config = HuffDeployer.config().with_code(wrapper_code).with_args(abi.encode(OWNER));
    vm.expectEmit(true, true, true, true);
    emit OwnerUpdated(address(config), OWNER);
    owner = Owned(config.deploy("auth/Owned"));
  }

  /// @notice Test that a non-matching selector reverts
    function testNonMatchingSelector(bytes32 callData) public {
        bytes4[] memory func_selectors = new bytes4[](2);
        func_selectors[0] = Owned.setOwner.selector;
        func_selectors[1] = Owned.owner.selector;

        
        bool success = nonMatchingSelectorHelper(
            func_selectors,
            callData,
            address(owner)
        );
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
