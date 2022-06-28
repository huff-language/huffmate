// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// import "forge-std/console.sol";

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Auth {
  function setOwner(address) external;
  function setAuthority(address) external;
  function owner() external returns (address);
  function authority() external returns (address);
}

contract HuffDeployerTest is Test {
    Auth auth;

    address constant OWNER = address(0x420);
    address constant INIT_AUTHORITY = address(0x0);

    event OwnerUpdated(address indexed user, address indexed newOwner);
    event AuthorityUpdated(address indexed user, address indexed newAuthority);

    function setUp() public {
      bytes memory owner = abi.encode(OWNER);
      bytes memory authority = abi.encode(INIT_AUTHORITY);

      // Create Constructor
      vm.expectEmit(true, true, true, true);
      emit AuthorityUpdated(address(this), INIT_AUTHORITY);
      emit OwnerUpdated(address(this), OWNER);
      auth = Auth(HuffDeployer.deploy_with_args(
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
      // TODO: create roles authority

      // Set the roles authority
      address new_authority = address(0x50ca1);
      vm.prank(OWNER);
      auth.setAuthority(new_authority);
      assertEq(new_authority, auth.authority());

      // Try to set the owner from the authority
      // vm.prank(new_authority);
      // auth.setOwner(new_authority);
      // assertEq(new_authority, auth.owner());
    }
}