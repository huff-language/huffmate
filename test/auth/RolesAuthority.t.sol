// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";
import { HuffConfig } from "foundry-huff/HuffConfig.sol";
import {NonMatchingSelectorsHelper} from "../test-utils/NonMatchingSelectorHelper.sol";


interface RolesAuthority {
  function hasRole(address user, uint8 role) external returns (bool);
  function doesRoleHaveCapability(uint8 role, address target, bytes4 functionSig) external returns (bool);
  function canCall(address user, address target, bytes4 functionSig) external returns (bool);
  function setPublicCapability(address target, bytes4 functionSig, bool enabled) external;
  function setRoleCapability(uint8 role, address target, bytes4 functionSig, bool enabled) external;
  function setUserRole(address user, uint8 role, bool enabled) external;
}

contract RolesAuthorityTest is Test, NonMatchingSelectorsHelper {
  RolesAuthority roleAuth;

  address constant OWNER = address(0x420);
  address constant INIT_AUTHORITY = address(0x0);

  // Events from Auth.sol
  event OwnerUpdated(address indexed user, address indexed newOwner);
  event AuthorityUpdated(address indexed user, address indexed newAuthority);

  function setUp() public {
    bytes memory owner = abi.encode(OWNER);
    bytes memory authority = abi.encode(INIT_AUTHORITY);

    // Grab wrapper code
    string memory wrapper_code = vm.readFile("test/auth/mocks/RolesAuthorityWrappers.huff");

    // Create the config deployer
    HuffConfig config = HuffDeployer.config().with_code(wrapper_code).with_args(bytes.concat(owner, authority));

    // Deploy and expect events
    vm.expectEmit(true, true, true, true);
    emit AuthorityUpdated(address(config), INIT_AUTHORITY);
    emit OwnerUpdated(address(config), OWNER);
    roleAuth = RolesAuthority(config.deploy("auth/RolesAuthority"));
  }

  /// @notice Test that a non-matching selector reverts
    function testNonMatchingSelector(bytes32 callData) public {
        bytes4[] memory func_selectors = new bytes4[](6);
        func_selectors[0] = RolesAuthority.hasRole.selector;
        func_selectors[1] = RolesAuthority.doesRoleHaveCapability.selector;
        func_selectors[2] = RolesAuthority.canCall.selector;
        func_selectors[3] = RolesAuthority.setPublicCapability.selector;
        func_selectors[4] = RolesAuthority.setRoleCapability.selector;
        func_selectors[5] = RolesAuthority.setUserRole.selector;

        bool success = nonMatchingSelectorHelper(
            func_selectors,
            callData,
            address(roleAuth)
        );
        assert(!success);
    }

  /// @notice Test if a user has a role.
  function testUserHasRole(address user) public {
    assertEq(false, roleAuth.hasRole(user, 8));
  }

  /// @notice Test checking if a role has a capability.
  function testRoleHasCapability(uint8 role, address user, bytes4 sig) public {
    assertEq(false, roleAuth.doesRoleHaveCapability(role, user, sig));
  }

  /// @notice Test checking if a user can call a target.
  function testCanCall(address user, address target, bytes4 sig) public {
    assertEq(false, roleAuth.canCall(user, target, sig));
  }

  /// @notice Test setting a public capability.
  function testSetPublicCapability(address caller, address target, bytes4 sig) public {
    if (caller == OWNER) return;
    vm.startPrank(caller);
    vm.expectRevert();
    roleAuth.setPublicCapability(target, sig, true);
    vm.stopPrank();

    vm.prank(OWNER);
    roleAuth.setPublicCapability(target, sig, true);
  }

  /// @notice Test setting a capability.
  function testSetRoleCapability(address caller, uint8 role, address target, bytes4 sig) public {
    if (caller == OWNER) return;
    vm.startPrank(caller);
    vm.expectRevert();
    roleAuth.setRoleCapability(role, target, sig, true);
    vm.stopPrank();

    // The role shouldn't have the capability
    assertEq(false, roleAuth.doesRoleHaveCapability(role, target, sig));

    vm.prank(OWNER);
    roleAuth.setRoleCapability(role, target, sig, true);

    // Verify that the role has the given capability
    assertEq(true, roleAuth.doesRoleHaveCapability(role, target, sig));
  }

  /// @notice Test setting a user's role.
  function testSetUserRole(address caller, uint8 role, address user) public {
    if (caller == OWNER) return;
    vm.startPrank(caller);
    vm.expectRevert();
    roleAuth.setUserRole(user, role, true);
    vm.stopPrank();

    assertEq(roleAuth.hasRole(user, role), false);

    vm.prank(OWNER);
    roleAuth.setUserRole(user, role, true);

    assertEq(roleAuth.hasRole(user, role), true);
  }
}
