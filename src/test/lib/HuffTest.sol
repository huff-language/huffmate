// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

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