// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Auth {
  function setOwner(address) external;
  function setAuthority(address) external;
  function owner() external returns (address);
  function authority() external returns (address);
}

interface RolesAuthority is Auth {
  function hasRole(address user, uint8 role) external returns (bool);
  function doesRoleHaveCapability(uint8 role, address target, bytes4 functionSig) external returns (bool);
  function canCall(address user, address target, bytes4 functionSig) external returns (bool);
  function setPublicCapability(address target, bytes4 functionSig, bool enabled) external;
  function setRoleCapability(uint8 role, address target, bytes4 functionSig, bool enabled) external;
  function setUserRole(address user, uint8 role, bool enabled) external;
}

contract AuthTest is Test {
  Auth auth;
  RolesAuthority rolesAuth;

  address constant OWNER = address(0x420);
  address constant INIT_AUTHORITY = address(0x421);

  event OwnerUpdated(address indexed user, address indexed newOwner);
  event AuthorityUpdated(address indexed user, address indexed newAuthority);

  function setUp() public {
    bytes memory owner = abi.encode(OWNER);
    bytes memory authority = abi.encode(INIT_AUTHORITY);

    // Deploy a roles authority for later use
    rolesAuth = RolesAuthority(
      HuffDeployer.deploy_with_args(
        "auth/RolesAuthority",
        bytes.concat(abi.encode(OWNER), abi.encode(OWNER))
    ));

    // Create Auth
    vm.expectEmit(true, true, true, true);
    emit AuthorityUpdated(address(this), INIT_AUTHORITY);
    emit OwnerUpdated(address(this), OWNER);
    auth = Auth(
      HuffDeployer.deploy_with_args(
        "auth/Auth",
        bytes.concat(owner, authority)
    ));
  }

  /// OWNER TESTS

  function testGetOwner() public {
    assertEq(OWNER, auth.owner());
  }

  function testSetOwner(address owner) public {
    if (owner == OWNER) return;
    vm.startPrank(owner);
    vm.expectRevert();
    auth.setOwner(owner);
    vm.stopPrank();
    assertEq(OWNER, auth.owner());
  }

  function testOwnerCanSetOwner() public {
    address new_owner = address(0x50ca1);
    vm.startPrank(OWNER);
    vm.expectEmit(true, true, true, true);
    emit OwnerUpdated(OWNER, new_owner);
    auth.setOwner(new_owner);
    vm.stopPrank();
    assertEq(new_owner, auth.owner());
  }

  /// AUTHORITY TESTS

  function testAuthority() public {
    assertEq(INIT_AUTHORITY, auth.authority());
  }

  function testSetAuthority(address owner) public {
    address new_authority = address(0x50ca1);
    if (owner == OWNER) return;
    vm.startPrank(owner);
    vm.expectRevert();
    auth.setAuthority(new_authority);
    vm.stopPrank();
    assertEq(INIT_AUTHORITY, auth.authority());
  }

  function testOwnerCanSetAuthority() public {
    address new_authority = address(0x50ca1);
    vm.startPrank(OWNER);
    vm.expectEmit(true, true, true, true);
    emit AuthorityUpdated(OWNER, new_authority);
    auth.setAuthority(new_authority);
    vm.stopPrank();
    assertEq(new_authority, auth.authority());
  }

  /// TEST AUTHORITY

  function testAuthoritiesCanSetAuthority() public {
    // Create Roles Auth for authority
    rolesAuth = RolesAuthority(
      HuffDeployer.deploy_with_args(
        "auth/RolesAuthority",
        bytes.concat(abi.encode(OWNER), abi.encode(OWNER))
    ));

    // Set roles auth as the authority
    vm.prank(OWNER);
    auth.setAuthority(address(rolesAuth));

    // Publicly set the capability
    vm.prank(OWNER);
    rolesAuth.setPublicCapability(address(auth), bytes4(0x7a9e5e4b), true);

    // Try to set the owner from the roles authority
    address new_authority = address(0x50ca1);
    vm.expectEmit(true, true, true, true);
    // vm.startPrank(address(rolesAuth));
    emit AuthorityUpdated(address(this), new_authority);
    auth.setAuthority(new_authority);
    // vm.stopPrank();
    assertEq(new_authority, auth.authority());

    vm.prank(OWNER);
    auth.setAuthority(INIT_AUTHORITY);
    assertEq(INIT_AUTHORITY, auth.authority());
  }

  function testAuthoritiesCannotSetAuthority(address user) public {
    if (user == OWNER) return;

    // Clean Roles Authority
    rolesAuth.setOwner(OWNER);
    rolesAuth.setAuthority(OWNER);
    vm.startPrank(OWNER);
    rolesAuth.setPublicCapability(address(auth), bytes4(0x13af4035), false); // setOwner
    rolesAuth.setPublicCapability(address(auth), bytes4(0x7a9e5e4b), false); // setAuthority
    vm.stopPrank();

    // Set roles auth as the authority
    vm.prank(OWNER);
    auth.setAuthority(address(rolesAuth));

    // NOTE: Although the authority is set,
    // NOTE: the capability for calling setOwner
    // NOTE: and setAuthority won't be allowed for the given user

    // Setting owner should fail from the user context
    vm.startPrank(user);
    vm.expectRevert();
    auth.setOwner(user);
    vm.stopPrank();
    assertEq(OWNER, auth.owner());

    // Setting authority should fail from the user context
    vm.startPrank(user);
    vm.expectRevert();
    auth.setAuthority(user);
    vm.stopPrank();
    assertEq(address(rolesAuth), auth.authority());

    // Reset the authority
    vm.prank(OWNER);
    auth.setAuthority(INIT_AUTHORITY);
    assertEq(INIT_AUTHORITY, auth.authority());
  }
}
