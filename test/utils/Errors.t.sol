// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

// Mock Interface
interface IErrorsMock {
    function simulateRequire() external pure;
    function simulateAssert() external pure;
    function simulateAssertEq() external pure;
    function simulateAssertNotEq() external pure;
    function simulateAssertMemEq() external pure;
    function simulateAssertMemNotEq() external pure;
    function simulateAssertStorageEq() external;
    function simulateAssertStorageNotEq() external;
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

uint256 constant COMPILER_PANIC = 0x00;
uint256 constant ASSERT_FALSE = 0x01;
uint256 constant ARITHMETIC_OVERFLOW = 0x11;
uint256 constant DIVIDE_BY_ZERO = 0x12;
uint256 constant INVALID_ENUM_VALUE = 0x21;
uint256 constant INVALID_STORAGE_BYTE_ARRAY = 0x22;
uint256 constant EMPTY_ARRAY_POP = 0x31;
uint256 constant ARRAY_OUT_OF_BOUNDS = 0x32;
uint256 constant MEMORY_TOO_LARGE = 0x41;
uint256 constant UNINITIALIZED_FUNCTION_POINTER = 0x51;

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
        string memory wrapper_code = vm.readFile("test/utils/mocks/ErrorWrappers.huff");
        eLib = IErrorsMock(HuffDeployer.deploy_with_code("utils/Errors", wrapper_code));
    }

    /// @dev Hack because `vm.expectRevert(bytes)` is bugged.
    function testRequire() public {
        // (bool success, bytes memory returnData) = address(eLib).call(
        //     abi.encodeCall(eLib.simulateRequire, ())
        // );

        // if (success) revert("call did not fail as expected");

        vm.expectRevert("revert");
        eLib.simulateRequire();
    }

    function testAssert() public {
        try eLib.simulateAssert() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertEq() public {
        try eLib.simulateAssertEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertNotEq() public {
        try eLib.simulateAssertNotEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertMemEq() public {
        try eLib.simulateAssertMemEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertMemNotEq() public {
        try eLib.simulateAssertMemNotEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertStorageEq() public {
        try eLib.simulateAssertStorageEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testAssertStorageNotEq() public {
        try eLib.simulateAssertStorageNotEq() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ASSERT_FALSE);
        }
    }

    function testCompilerPanic() public {
        try eLib.simulateCompilerPanic() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, COMPILER_PANIC);
        }
    }

    function testArithmeticOverflow() public {
        try eLib.simulateArithmeticOverflow() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ARITHMETIC_OVERFLOW);
        }
    }

    function testDivideByZero() public {
        try eLib.simulateDivideByZero() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, DIVIDE_BY_ZERO);
        }
    }

    function testInvalidEnumValue() public {
        try eLib.simulateInvalidEnumValue() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, INVALID_ENUM_VALUE);
        }
    }

    function testInvalidStorageByteArray() public {
        try eLib.simulateInvalidStorageByteArray() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, INVALID_STORAGE_BYTE_ARRAY);
        }
    }

    function testEmptyArrayPop() public {
        try eLib.simulateEmptyArrayPop() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, EMPTY_ARRAY_POP);
        }
    }

    function testArrayOutOfBounds() public {
        try eLib.simulateArrayOutOfBounds() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, ARRAY_OUT_OF_BOUNDS);
        }
    }

    function testMemoryTooLarge() public {
        try eLib.simulateMemoryTooLarge() {
            revert("did not fail");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, MEMORY_TOO_LARGE);
        }
    }

    function testUninitializedFunctionPointer() public {
        try eLib.simulateUninitializedFunctionPointer() {
            revert("did not revert");
        } catch Panic(uint256 panicCode) {
            assertEq(panicCode, UNINITIALIZED_FUNCTION_POINTER);
        }
    }
}
