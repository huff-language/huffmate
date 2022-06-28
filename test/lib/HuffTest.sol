// SPDX-License-Identifier: UNLICENSED
<<<<<<< HEAD:src/test/lib/HuffTest.sol
pragma solidity 0.8.13;
=======
pragma solidity ^0.8.15;
>>>>>>> main:test/lib/HuffTest.sol

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