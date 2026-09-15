// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";
import { HuffConfig } from "foundry-huff/HuffConfig.sol";
import {NonMatchingSelectorsHelper} from "../test-utils/NonMatchingSelectorHelper.sol";
import {RolesAuthority as SolmateRolesAuthority} from "solmate/auth/authorities/RolesAuthority.sol";
import {Authority} from "solmate/auth/Auth.sol";


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

  /// @dev Reference implementation used to assert the expected behaviour of the huff port
  SolmateRolesAuthority solmateRoleAuth;

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

    // Deploy the solmate reference implementation with the same owner / authority
    solmateRoleAuth = new SolmateRolesAuthority(OWNER, Authority(INIT_AUTHORITY));
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

  /*//////////////////////////////////////////////////////////////
                  CAPABILITY MAPPING COLLISION TESTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Granting a capability to a role must not make that capability public.
  /// @dev Regression test: `isCapabilityPublic` and `getRolesWithCapability` were both
  ///      keyed on `keccak256(target, functionSig)` without a distinct mapping slot, so
  ///      writing a role bitmap for a capability was misread as the capability being public.
  function testSetRoleCapabilityDoesNotMakeCapabilityPublic() public {
    uint8 role = 5;
    address target = address(0xCAFE);
    bytes4 sig = bytes4(0xBEEFCAFE);
    address user = address(0xBEEF);

    // Nothing has been configured yet
    assertFalse(roleAuth.canCall(user, target, sig));

    // Only grant the capability to the role. It is NOT made public.
    vm.prank(OWNER);
    roleAuth.setRoleCapability(role, target, sig, true);
    assertTrue(roleAuth.doesRoleHaveCapability(role, target, sig));

    // The user holds no roles, so it must not be authorized
    assertFalse(roleAuth.hasRole(user, role));
    assertFalse(roleAuth.canCall(user, target, sig));

    // Once the user is granted the role it must be authorized
    vm.prank(OWNER);
    roleAuth.setUserRole(user, role, true);
    assertTrue(roleAuth.canCall(user, target, sig));

    // Revoking the role must revoke access again
    vm.prank(OWNER);
    roleAuth.setUserRole(user, role, false);
    assertFalse(roleAuth.canCall(user, target, sig));
  }

  /// @notice Making a capability public must not grant it to any role.
  /// @dev The inverse of the collision: `setPublicCapability(.., true)` stores a `1`, which
  ///      was misread as role `0` holding the capability.
  function testSetPublicCapabilityDoesNotGrantRoleCapability() public {
    address target = address(0xCAFE);
    bytes4 sig = bytes4(0xBEEFCAFE);

    vm.prank(OWNER);
    roleAuth.setPublicCapability(target, sig, true);

    // Anyone can call a public capability
    assertTrue(roleAuth.canCall(address(0xBEEF), target, sig));

    // But no role has been granted the capability
    assertFalse(roleAuth.doesRoleHaveCapability(0, target, sig));

    // Disabling a public capability must not clear a previously granted role capability
    vm.prank(OWNER);
    roleAuth.setRoleCapability(3, target, sig, true);
    vm.prank(OWNER);
    roleAuth.setPublicCapability(target, sig, false);
    assertTrue(roleAuth.doesRoleHaveCapability(3, target, sig));
    assertFalse(roleAuth.canCall(address(0xBEEF), target, sig));
  }

  /// @notice Equivalent of `testSetRoleCapabilityDoesNotMakeCapabilityPublic` run against the
  ///         solmate reference implementation, asserting the behaviour the huff port must match.
  function testSolmateSetRoleCapabilityDoesNotMakeCapabilityPublic() public {
    uint8 role = 5;
    address target = address(0xCAFE);
    bytes4 sig = bytes4(0xBEEFCAFE);
    address user = address(0xBEEF);

    assertFalse(solmateRoleAuth.canCall(user, target, sig));

    vm.prank(OWNER);
    solmateRoleAuth.setRoleCapability(role, target, sig, true);
    assertTrue(solmateRoleAuth.doesRoleHaveCapability(role, target, sig));

    assertFalse(solmateRoleAuth.doesUserHaveRole(user, role));
    assertFalse(solmateRoleAuth.canCall(user, target, sig));

    vm.prank(OWNER);
    solmateRoleAuth.setUserRole(user, role, true);
    assertTrue(solmateRoleAuth.canCall(user, target, sig));

    vm.prank(OWNER);
    solmateRoleAuth.setUserRole(user, role, false);
    assertFalse(solmateRoleAuth.canCall(user, target, sig));
  }

  /// @notice Differential fuzz: the huff port must agree with solmate for any combination of
  ///         role capability / public capability / user role configuration.
  function testFuzzCanCallMatchesSolmate(
    uint8 role,
    address target,
    bytes4 sig,
    address user,
    bool roleEnabled,
    bool publicEnabled,
    bool userHasRole
  ) public {
    vm.startPrank(OWNER);
    roleAuth.setRoleCapability(role, target, sig, roleEnabled);
    solmateRoleAuth.setRoleCapability(role, target, sig, roleEnabled);

    roleAuth.setPublicCapability(target, sig, publicEnabled);
    solmateRoleAuth.setPublicCapability(target, sig, publicEnabled);

    roleAuth.setUserRole(user, role, userHasRole);
    solmateRoleAuth.setUserRole(user, role, userHasRole);
    vm.stopPrank();

    assertEq(roleAuth.hasRole(user, role), solmateRoleAuth.doesUserHaveRole(user, role));
    assertEq(roleAuth.doesRoleHaveCapability(role, target, sig), solmateRoleAuth.doesRoleHaveCapability(role, target, sig));
    assertEq(roleAuth.canCall(user, target, sig), solmateRoleAuth.canCall(user, target, sig));

    // Expected outcome spelled out explicitly
    assertEq(roleAuth.canCall(user, target, sig), publicEnabled || (roleEnabled && userHasRole));
  }
}
