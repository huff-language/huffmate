// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

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
        return new HuffDeployer().deploy(name);
    }
}