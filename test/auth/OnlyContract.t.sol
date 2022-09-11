// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";

contract OnlyContractTest is Test {
    address only_contract;

    function setUp() public {
        HuffConfig config = HuffDeployer.config().with_code(string.concat(
            "#define macro MAIN() = takes(0) returns(0) {\n",
            "  ONLY_CONTRACT()\n",
            "  0x00 0x00 log0 // anonymous log\n",
            "  0x01 0x00 mstore\n",
            "  0x20 0x00 return\n",
            "}\n"
        ));
        only_contract = config.deploy("auth/OnlyContract");
    }

    /// @notice Tests that ONLY_CONTRACT macro reverts when tx.origin == msg.sender
    function testOnlyContract(address caller) public {
        // foundry's tx.origin = 0x00a329c0648769A73afAc7F9381E08FB43dBEA72
        vm.assume(caller != tx.origin);

        // Should revert when tx.origin == msg.sender
        // vm.startPrank(address,address) sets msg.sender and tx.origin
        vm.startPrank(caller, caller);
        vm.expectRevert();
        only_contract.call("");
        vm.stopPrank();

        // Only setting the msg.sender and not tx.origin should succeed, so long as
        // caller != 0x00a329c0648769A73afAc7F9381E08FB43dBEA72, which is the default tx.origin
        vm.startPrank(caller);
        (bool success,) = only_contract.call("");
        assert(success);
        vm.stopPrank();
    }
}
