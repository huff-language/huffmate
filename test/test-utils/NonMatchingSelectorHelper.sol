// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

<<<<<<< HEAD
abstract contract NonMatchingSelectorsHelper {
    /// @dev Expected to return false.
=======
/**
 * expected to fail
 */
abstract contract NonMatchingSelectorsHelper {
>>>>>>> bde0a4d (added helper for testing non matching selectors)
    function nonMatchingSelectorHelper(
        bytes4[] memory func_selectors,
        bytes32 callData,
        address target
    ) internal returns (bool) {
<<<<<<< HEAD
        bytes4 func_selector = bytes4(callData);
    
=======
        bytes4 func_selector;
        assembly {
            func_selector := and(
                callData,
                0xffffffff00000000000000000000000000000000000000000000000000000000
            )
        }
        console.logBytes4(func_selector);
        console.logBytes4(func_selectors[0]);

>>>>>>> bde0a4d (added helper for testing non matching selectors)
        for (uint256 i = 0; i < func_selectors.length; i++) {
            if (func_selector == func_selectors[i]) {
                return false;
            }
        }

        bool success = false;
        assembly {
            mstore(0x80, callData)
            // if its a state changing call this will return 0
            success := staticcall(gas(), target, 0x80, 0x20, 0, 0)

            if iszero(success) {
                success := call(gas(), target, 0, 0x80, 0x20, 0, 0)
            }
        }
        return success;
    }
}