// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IMulticallable {
    function multicall(bytes[] calldata) external payable returns (bytes[] memory);
    function paid() external view returns (uint256);
}

contract MulticallableTest is Test {
    IMulticallable multicallable;

    function setUp() public {
        /// @notice deploy a new instance of IMulticallable by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/MulticallableWrappers.huff");
        multicallable = IMulticallable(HuffDeployer.deploy_with_code("utils/Multicallable", wrapper_code));
    }

    function testRevertNoMsg() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("call1()");
        data[1] = abi.encodeWithSignature("call2()");
        data[2] = abi.encodeWithSignature("revertsNoMsg()");

        vm.expectRevert();
        multicallable.multicall(data);
    }

    function testRevertCustomMsg() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSignature("call1()");
        data[1] = abi.encodeWithSignature("call2()");
        data[2] = abi.encodeWithSignature("revertsMsg()");

        vm.expectRevert(bytes("Test Revert"));
        multicallable.multicall(data);
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

    function testReturnDataIsProperlyEncoded(
        uint256 a0,
        uint256 b0,
        uint256 a1,
        uint256 b1
    ) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("returnsTuple(uint256,uint256)", a0, b0);
        data[1] = abi.encodeWithSignature("returnsTuple(uint256,uint256)", a1, b1);
        bytes[] memory output = multicallable.multicall(data);

        (uint256 _a0, uint256 _b0) = abi.decode(output[0], (uint256, uint256));
        assertEq(a0, _a0);
        assertEq(b0, _b0);
        (uint256 _a1, uint256 _b1) = abi.decode(output[1], (uint256, uint256));
        assertEq(a1, _a1);
        assertEq(b1, _b1);
    }

    function testReturnDataIsProperlyEncoded(string memory str) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("returnsStr(string)", str);
        data[1] = abi.encodeWithSignature("returnsStr(string)", str);
        bytes[] memory output = multicallable.multicall(data);

        (string memory outStr0) = abi.decode(output[0], (string));
        assertEq(str, outStr0);

        (string memory outStr1) = abi.decode(output[1], (string));
        assertEq(str, outStr1);
    }

    function testWithNoData() public {
        bytes[] memory data = new bytes[](0);
        assertEq(multicallable.multicall(data).length, 0);
    }

    function testPreservesMsgValue() public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("pay()");
        multicallable.multicall{value: 3}(data);
        assertEq(multicallable.paid(), 3);
    }

    function testPreservesMsgValueUsedTwice() public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("pay()");
        data[1] = abi.encodeWithSignature("pay()");
        multicallable.multicall{value: 3}(data);
        assertEq(multicallable.paid(), 6);
    }

    function testPreservesMsgSender() public {
        address caller = address(uint160(0xbeef));
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("returnsSender()");
        vm.prank(caller);
        address returnedAddress = abi.decode(multicallable.multicall(data)[0], (address));
        assertEq(caller, returnedAddress);
    }
}