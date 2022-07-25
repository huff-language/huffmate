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
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSignature("call1()");
        calls[1] = abi.encodeWithSignature("call2()");
        
        bytes[] memory result = multicallable.multicall(calls);
        emit log_named_uint("result length", result.length);
        for (uint i; i < result.length; i++) {
            emit log_bytes(result[i]);
        }
    }
}