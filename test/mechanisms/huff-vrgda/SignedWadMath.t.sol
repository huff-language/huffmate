// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import {
    toWadUnsafe,
    toDaysWadUnsafe,
    fromDaysWadUnsafe,
    unsafeWadMul,
    unsafeWadDiv,
    unsafeDiv,
    wadMul,
    wadDiv,
    wadExp,
    wadLn
} from "./utils/SignedWadMath.sol";

/// @notice The Huff SignedWadMath surface under test.
interface ISignedWadMath {
    function toWadUnsafe(uint256) external returns (int256);
    function toDaysWadUnsafe(uint256) external returns (int256);
    function fromDaysWadUnsafe(int256) external returns (uint256);
    function unsafeWadMul(int256, int256) external returns (int256);
    function unsafeWadDiv(int256, int256) external returns (int256);
    function unsafeDiv(int256, int256) external returns (int256);
    function wadMul(int256, int256) external returns (int256);
    function wadDiv(int256, int256) external returns (int256);
    function wadExp(int256) external returns (int256);
    function wadLn(int256) external returns (int256);
    function powWad(int256, int256) external returns (int256);
    function log2(uint256) external returns (uint256);
}

/// @notice Wraps the reference free functions as *external* functions so the
///         reverting ones can be probed with try/catch for revert-parity.
contract Ref {
    function toWadUnsafe(uint256 x) external pure returns (int256) { return toWadUnsafe(x); }
    function toDaysWadUnsafe(uint256 x) external pure returns (int256) { return toDaysWadUnsafe(x); }
    function fromDaysWadUnsafe(int256 x) external pure returns (uint256) { return fromDaysWadUnsafe(x); }
    function unsafeWadMul(int256 x, int256 y) external pure returns (int256) { return unsafeWadMul(x, y); }
    function unsafeWadDiv(int256 x, int256 y) external pure returns (int256) { return unsafeWadDiv(x, y); }
    function unsafeDiv(int256 x, int256 y) external pure returns (int256) { return unsafeDiv(x, y); }
    function wadMul(int256 x, int256 y) external pure returns (int256) { return wadMul(x, y); }
    function wadDiv(int256 x, int256 y) external pure returns (int256) { return wadDiv(x, y); }
    function wadExp(int256 x) external pure returns (int256) { return wadExp(x); }
    function wadLn(int256 x) external pure returns (int256) { return wadLn(x); }

    /// @dev Mirrors solmate's powWad and the Huff POW_WAD exactly:
    ///      expWad( sdiv(mul(lnWad(x), y), 1e18) )
    function powWad(int256 x, int256 y) external pure returns (int256) {
        int256 l = wadLn(x);           // reverts if x <= 0
        int256 z;
        assembly { z := sdiv(mul(l, y), 1000000000000000000) }
        return wadExp(z);              // reverts on overflow
    }

    /// @dev floor(log2(x)); reverts on x == 0, matching the Huff LOG_2.
    function log2(uint256 x) external pure returns (uint256 r) {
        require(x != 0, "UNDEFINED");
        while (x > 1) { x >>= 1; r++; }
    }
}

contract SignedWadMathTest is Test {
    ISignedWadMath huff;
    Ref ref;

    int256 constant WAD = 1e18;

    function setUp() public {
        ref = new Ref();
        string memory wrapper = vm.readFile("test/mechanisms/huff-vrgda/mocks/SignedWadMathWrappers.huff");
        huff = ISignedWadMath(
            HuffDeployer.deploy_with_code("mechanisms/huff-vrgda/SignedWadMath", wrapper)
        );
    }

    /* ------------------------------------------------------------------ */
    /*                    NON-REVERTING OPS: EXACT MATCH                   */
    /* ------------------------------------------------------------------ */

    function testDiff_toWadUnsafe(uint256 x) public {
        assertEq(huff.toWadUnsafe(x), ref.toWadUnsafe(x));
    }

    function testDiff_toDaysWadUnsafe(uint256 x) public {
        assertEq(huff.toDaysWadUnsafe(x), ref.toDaysWadUnsafe(x));
    }

    function testDiff_fromDaysWadUnsafe(int256 x) public {
        assertEq(huff.fromDaysWadUnsafe(x), ref.fromDaysWadUnsafe(x));
    }

    function testDiff_unsafeWadMul(int256 x, int256 y) public {
        assertEq(huff.unsafeWadMul(x, y), ref.unsafeWadMul(x, y));
    }

    function testDiff_unsafeWadDiv(int256 x, int256 y) public {
        assertEq(huff.unsafeWadDiv(x, y), ref.unsafeWadDiv(x, y));
    }

    function testDiff_unsafeDiv(int256 x, int256 y) public {
        assertEq(huff.unsafeDiv(x, y), ref.unsafeDiv(x, y));
    }

    /* ------------------------------------------------------------------ */
    /*                REVERTING OPS: VALUE + REVERT PARITY                 */
    /* ------------------------------------------------------------------ */

    function testDiff_wadMul(int256 x, int256 y) public {
        try ref.wadMul(x, y) returns (int256 e) {
            assertEq(huff.wadMul(x, y), e);
        } catch {
            vm.expectRevert();
            huff.wadMul(x, y);
        }
    }

    function testDiff_wadDiv(int256 x, int256 y) public {
        try ref.wadDiv(x, y) returns (int256 e) {
            assertEq(huff.wadDiv(x, y), e);
        } catch {
            vm.expectRevert();
            huff.wadDiv(x, y);
        }
    }

    function testDiff_wadExp(int256 x) public {
        try ref.wadExp(x) returns (int256 e) {
            assertEq(huff.wadExp(x), e);
        } catch {
            vm.expectRevert();
            huff.wadExp(x);
        }
    }

    function testDiff_wadLn(int256 x) public {
        try ref.wadLn(x) returns (int256 e) {
            assertEq(huff.wadLn(x), e);
        } catch {
            vm.expectRevert();
            huff.wadLn(x);
        }
    }

    function testDiff_powWad(int256 x, int256 y) public {
        // Keep the base positive and exponents in a sane band so a healthy
        // fraction of runs exercise the non-reverting path; try/catch covers the rest.
        x = bound(x, 1, int256(1e30));
        y = bound(y, -20e18, 20e18);
        try ref.powWad(x, y) returns (int256 e) {
            assertEq(huff.powWad(x, y), e);
        } catch {
            vm.expectRevert();
            huff.powWad(x, y);
        }
    }

    function testDiff_log2(uint256 x) public {
        try ref.log2(x) returns (uint256 e) {
            assertEq(huff.log2(x), e);
        } catch {
            vm.expectRevert();
            huff.log2(x);
        }
    }

    /* ------------------------------------------------------------------ */
    /*                     TARGETED DOMAIN-BOUNDARY CASES                  */
    /* ------------------------------------------------------------------ */

    function testExp_boundaries() public {
        // Underflow boundary: x <= -42139678854452767551 returns 0.
        assertEq(huff.wadExp(-42139678854452767551), 0);
        assertEq(huff.wadExp(type(int256).min), 0);
        assertEq(huff.wadExp(-42139678854452767551 + 1), ref.wadExp(-42139678854452767551 + 1));

        // Overflow boundary: x >= 135305999368893231589 reverts.
        vm.expectRevert();
        huff.wadExp(135305999368893231589);
        vm.expectRevert();
        huff.wadExp(type(int256).max);

        // Just below the overflow boundary must succeed and match.
        assertEq(huff.wadExp(135305999368893231589 - 1), ref.wadExp(135305999368893231589 - 1));
    }

    function testLn_boundaries() public {
        // Undefined for x <= 0.
        vm.expectRevert();
        huff.wadLn(0);
        vm.expectRevert();
        huff.wadLn(-1);
        vm.expectRevert();
        huff.wadLn(type(int256).min);

        // ln(1e18) == 0, ln(1) is very negative — both must match the reference.
        assertEq(huff.wadLn(WAD), ref.wadLn(WAD));
        assertEq(huff.wadLn(1), ref.wadLn(1));
        assertEq(huff.wadLn(type(int256).max), ref.wadLn(type(int256).max));
    }

    /* ------------------------------------------------------------------ */
    /*                  KNOWN-ANSWER ANCHORS (vs real math)               */
    /* ------------------------------------------------------------------ */

    function testExp_knownAnswers() public {
        assertEq(huff.wadExp(0), WAD);                       // e^0 = 1
        // e^1 ~= 2.718281828e18
        assertApproxEqRel(huff.wadExp(WAD), 2718281828459045235, 1e12);
        // e^-1 ~= 0.367879441e18
        assertApproxEqRel(huff.wadExp(-WAD), 367879441171442321, 1e12);
    }

    function testLn_knownAnswers() public {
        assertEq(huff.wadLn(WAD), 0);                        // ln(1) = 0
        // ln(e) = 1e18 where e ~= 2.718281828e18
        assertApproxEqRel(huff.wadLn(2718281828459045235), WAD, 1e12);
    }

    function testWadMul_knownAnswers() public {
        assertEq(huff.wadMul(3 * WAD, 2 * WAD), 6 * WAD);
        assertEq(huff.wadMul(-3 * WAD, 2 * WAD), -6 * WAD);
        assertEq(huff.unsafeWadMul(3 * WAD, 2 * WAD), 6 * WAD);
    }
}
