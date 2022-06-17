// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Test} from "forge-std/Test.sol";

interface Cheats {
    function ffi(string[] calldata) external returns (bytes memory);
}

error DeploymentFailed();

/// @title Huff Tester Base. Extends Forge-Std Test.
/// @dev Inherit to access `deploy`
contract HuffTester is Test {

    /// @dev Deploys Huff contract by its path from project root
    /// @param path Path from root. Example: "src/Address.huff"
    /// @return huffCon Huff contract address
    function deploy(string memory path) internal returns (address huffCon) {
        // Setting up the FFI command
        string[] memory cmds = new string[](4);
        cmds[0] = "huffc";
        cmds[1] = path;
        cmds[2] = "--bytecode";
        cmds[3] = "-n";

        // Getting bytecode from huff compiler
        bytes memory bytecode = Cheats(address(vm)).ffi(cmds);
        bytes32 salt = keccak256("huff");

        assembly {
            // create2 because I'm a degenerate
            huffCon := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        // Throw if deployment failed. Might not need this.
        if (huffCon.codehash == bytes32(0)) revert DeploymentFailed(); 
    }
}
