// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IMulticallable {
    function multicall(bytes[] calldata) external pure returns (bytes[] memory);
}

contract MulticallableTest is Test {
    IMulticallable multicallable;

    function setUp() public {
        /// @notice deploy a new instance of IMulticallable by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/MulticallableWrappers.huff");
        multicallable = IMulticallable(HuffDeployer.deploy_with_code("utils/Multicallable", wrapper_code));
    }

    function testBasicMulticall() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("call1()");
        data[1] = abi.encodeWithSignature("call2()");
        data[2] = abi.encodeWithSignature("call3()");
        bytes[] memory output = multicallable.multicall(data);

        (uint a) = abi.decode(output[0], (uint));
        assertEq(a, 0x11);
        (uint b) = abi.decode(output[1], (uint));
        assertEq(b, 0x22);
        (uint c) = abi.decode(output[2], (uint));
        assertEq(c, 0x33);
    }

    function testRevertNoMsg() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("call1()");
        data[1] = abi.encodeWithSignature("call2()");
        data[2] = abi.encodeWithSignature("revertsNoMsg()");

        vm.expectRevert();
        bytes[] memory output = multicallable.multicall(data);
    }

    function testRevertCustomMsg() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("call1()");
        data[1] = abi.encodeWithSignature("call2()");
        data[2] = abi.encodeWithSignature("revertsMsg()");

        vm.expectRevert(bytes("Test Revert"));
        bytes[] memory output = multicallable.multicall(data);
    }

    function testReturnDataIsProperlyEncoded(uint a0, uint b0, uint a1, uint b1) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("returnsTuple(uint256,uint256)", a0, b0);
        data[1] = abi.encodeWithSignature("returnsTuple(uint256,uint256)", a1, b1);
        bytes[] memory output = multicallable.multicall(data);

        (uint _a0, uint _b0) = abi.decode(output[0], (uint, uint));
        assertEq(a0, _a0);
        assertEq(b0, _b0);
        (uint _a1, uint _b1) = abi.decode(output[1], (uint, uint));
        assertEq(a1, _a1);
        assertEq(b1, _b1);
    }
}