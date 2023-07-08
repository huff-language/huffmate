// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";

contract NonPayableTest is Test {
  address np;

  function setUp() public {
    HuffConfig config = HuffDeployer.config().with_code(string.concat(
      "#define macro MAIN() = takes(0) returns(0) {\n",
      "  NON_PAYABLE()\n",
      "  0x00 0x00 log0 // anonymous log\n",
      "  0x01 0x00 mstore\n",
      "  0x20 0x00 return\n",
      "}\n"
    ));
    np = config.deploy("auth/NonPayable");
  }

  /// @notice Test that a non-matching signature reverts
  function testNonPayable(bytes32 callData) public {
    // Should revert for any call data where a value is sent
    vm.expectRevert();
    (bool fails,) = np.call{value: 1 ether}(abi.encode(callData));

    // Non value calls should succeed
    (bool success, bytes memory retBytes) = np.call(abi.encode(callData));
    assert(success);
    assertEq(bytes8(retBytes[31]), bytes8(hex"01"));
  }
}
