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
    }

    /// @dev Hack because `vm.expectRevert(bytes)` is bugged.
    function testRequire() public {
        (bool success, bytes memory returnData) = address(eLib).call(
            abi.encodeCall(eLib.simulateRequire, ())
        );

        if (success) revert("call did not fail as expected");

        assertEq(
            keccak256(returnData),
            keccak256(hex"08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000006726576657274")
        );
    }

    function testAssert() public {
        try eLib.simulateAssert() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, 1);
        }
    }
}
