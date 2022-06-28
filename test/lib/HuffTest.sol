// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

contract HuffTest is Test {
    /// @dev The name of the contract.
    string internal name;

    /// @dev Create a new HuffTest contract.
    constructor(string memory _name) {
        name = _name;
    }

    /// @dev Deploy a new contract.
    function deploy() internal returns (address) {
        return HuffDeployer.deploy(name);
    }
}