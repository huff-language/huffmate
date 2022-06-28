// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// import "forge-std/console.sol";

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Auth {
  function setOwner(address) external;
  function setAuthority(address) external;
  function owner() external returns (address);
}

contract HuffDeployerTest is Test {
    Auth auth;

    function setUp() public {
      auth = Auth(HuffDeployer.deploy("auth/Auth"));
    }

    function testGetOwner() public {
      address owner = auth.owner();
      // assertEq(address(this), auth.owner());
    }

    function testSetOwner(address owner) public {
      if (owner == address(0)) vm.expectRevert();
      auth.setOwner(owner);
      // assertEq(owner, auth.OWNER());
    }
}