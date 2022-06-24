// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// import "forge-std/console.sol";

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface Auth {
  function setOwner(address) external;
  function setAuthority(address) external;
}

contract HuffDeployerTest is Test {
    ///@notice create a new instance of HuffDeployer
    HuffDeployer huffDeployer = new HuffDeployer();

    Auth auth;

    function setUp() public {
      auth = Auth(huffDeployer.deploy("auth/Auth"));

    }

    function testSetOwner(address owner) public {
      if (owner == address(0)) vm.expectRevert();
      auth.setOwner(owner);
      // assertEq(owner, auth.OWNER());
    }
}