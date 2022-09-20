// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

interface IShuffler {
    // TODO ...
}

contract ShufflingTest is Test {
    IShuffler shuffler;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/ShufflingWrappers.huff");
        shuffler = IShuffler(HuffDeployer.deploy_with_code("utils/Shuffling", wrapper_code));
    }

    function testShuffle() public {
        // TODO ...
    }

}