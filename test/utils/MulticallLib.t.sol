// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IMulticallable {
    function multicall(bytes[] calldata) external pure returns (bytes[] memory);
}

contract MerkleProofLibTest is Test {
    IMulticallable multicallable;

    function setUp() public {
        /// @notice deploy a new instance of IMulticallable by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/MulticallableWrappers.huff");
        multicallable = IMulticallable(HuffDeployer.deploy_with_code("utils/Multicallable", wrapper_code));
    }

    function testMulticall() public {
        bytes[] memory test = new bytes[](3);
        test[0] = abi.encodeWithSignature("call1()");
        test[1] = abi.encodeWithSignature("call2()");
        test[2] = abi.encodeWithSignature("call3()");
        bytes[] memory test2 = multicallable.multicall(test);

        (uint a) = abi.decode(test2[0], (uint));
        assertEq(a, 0x11);
        (uint b) = abi.decode(test2[1], (uint));
        assertEq(b, 0x22);
        (uint c) = abi.decode(test2[2], (uint));
        assertEq(c, 0x33);
    }
}