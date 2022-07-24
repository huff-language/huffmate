// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

// Mock Interface
interface IErrorsMock {
    function simulateRequire() external pure;
    function simulateAssert() external pure;
    function simulateCompilerPanic() external pure;
    function simulateArithmeticOverflow() external pure;
    function simulateDivideByZero() external pure;
    function simulateInvalidEnumValue() external pure;
    function simulateInvalidStorageByteArray() external pure;
    function simulateEmptyArrayPop() external pure;
    function simulateArrayOutOfBounds() external pure;
    function simulateMemoryTooLarge() external pure;
    function simulateUninitializedFunctionPointer() external pure;
    function simulateBubbleUpIfFailed(address) external view;
}

// Utils
bytes4 constant errorSelector = 0x08c379a0;
bytes4 constant panicSelector = 0x4e487b71;
function _encodeError(string memory message) pure returns (bytes memory) {
    return abi.encodeWithSelector(errorSelector, message);
}
function _encodePanic(uint256 code) pure returns (bytes memory) {
    return abi.encodeWithSelector(panicSelector, code);
}

contract ErrorsTest is Test {
    IErrorsMock eLib;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/ErrorsMock.huff");
        eLib = IErrorsMock(HuffDeployer.deploy_with_code("utils/Errors", wrapper_code));
        console.logBytes(address(eLib).code);
    }

    function testRequire() public {
        vm.expectRevert(bytes("revert"));
        eLib.simulateRequire();
    }
}
