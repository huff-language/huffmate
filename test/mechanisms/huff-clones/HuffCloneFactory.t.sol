// SPDX-License-Identifier: BSD
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {IExampleClone, IExampleCloneFactory} from "./Interfaces.sol";

contract HuffCloneFactoryTest is Test {
    IExampleCloneFactory internal factory;

    function setUp() public {
        IExampleClone impl = IExampleClone(HuffDeployer.deploy("mechanisms/huff-clones/ExampleClone"));
        factory = IExampleCloneFactory(
            HuffDeployer.deploy_with_args("mechanisms/huff-clones/ExampleCloneFactory", abi.encode(address(impl)))
        );
    }

    /// -----------------------------------------------------------------------
    /// Gas benchmarking
    /// -----------------------------------------------------------------------

    function testGas_clone(
        address param1,
        uint256 param2,
        uint64 param3,
        uint8 param4
    ) public {
        factory.createClone(param1, param2, param3, param4);
    }

    function testGas_arrClone(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public {
        uint256[] memory arr = new uint256[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;

        factory.createArrClone(arr);
    }

    /// -----------------------------------------------------------------------
    /// Correctness tests
    /// -----------------------------------------------------------------------

    function testCorrectness_clone(
        address param1,
        uint256 param2,
        uint64 param3,
        uint8 param4
    ) public {
        IExampleClone clone = IExampleClone(factory.createClone(
            param1,
            param2,
            param3,
            param4
        ));
        assertEq(clone.param1(), param1);
        assertEq(clone.param2(), param2);
        assertEq(clone.param3(), param3);
        assertEq(clone.param4(), param4);
    }

    function testCorrectness_arrClone(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public {
        uint256[] memory arr = new uint256[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;

        IExampleClone clone = IExampleClone(factory.createArrClone(arr));
        assertEq(clone.param5(arr.length), arr);
    }
}
