// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface RolesAuthority {
  function hasRole(address, uint8) external returns (bool);
  function doesRoleHaveCapability(uint8, address, bytes4) external returns (bool);
}

contract RolesAuthorityTest is Test {
    RolesAuthority roleAuth;

    address constant OWNER = address(0x420);
    address constant INIT_AUTHORITY = address(0x0);

    // Events from Auth.sol
    event OwnerUpdated(address indexed user, address indexed newOwner);
    event AuthorityUpdated(address indexed user, address indexed newAuthority);

    function setUp() public {
      bytes memory owner = abi.encode(OWNER);
      bytes memory authority = abi.encode(INIT_AUTHORITY);

      // Deploy RolesAuthority
      vm.expectEmit(true, true, true, true);
      emit AuthorityUpdated(address(this), INIT_AUTHORITY);
      emit OwnerUpdated(address(this), OWNER);
      roleAuth = RolesAuthority(HuffDeployer.deploy_with_args(
          "auth/RolesAuthority",
          bytes.concat(owner, authority)
      ));
    }

    /// @notice Test if a user has a role.
    function testUserHasRole(address user) public {
      assertEq(false, roleAuth.hasRole(user, 8));
    }

    /// @notice Test checking if a role has a capability.
    function testRoleHasCapability(uint8 role, address user, bytes4 sig) public {
      assertEq(false, roleAuth.doesRoleHaveCapability(role, user, sig));
    }
}