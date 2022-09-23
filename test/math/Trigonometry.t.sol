// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface ITrigonometry {
    function sin(uint256) external pure returns (int256);
    function cos(uint256) external pure returns (int256);
}

/// @dev Tests adapted from https://github.com/mds1/solidity-trigonometry/blob/main/src/test/Trigonometry.t.sol
contract TrigonometryTest is Test {
    ITrigonometry trig;
    uint256 constant TOL = 1.5e14;
    uint256 constant PI = 3141592653589793238;
    uint256 constant SCALE = 1e18 * 2 * PI;

    function setUp() public {
        /// @notice deploy a new instance of ITrigonometry by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/math/mocks/TrigonometryWrappers.huff");
        trig = ITrigonometry(HuffDeployer.deploy_with_code("math/Trigonometry", wrapper_code));
    }

    ////////////////////////////////////////////////////////////////
    //                            SINE                            //
    ////////////////////////////////////////////////////////////////

    function testNoRevertsSin(uint256 _angle) public {
        trig.sin(_angle);
    }

    function testSin1() public {
        assertApproxEq(trig.sin(0), 0, TOL);
    }

    function testSin2() public {
        assertApproxEq(trig.sin(PI / 8), 382683432365089800, TOL);
    }

    function testSin3() public {
        assertApproxEq(trig.sin(PI / 4), 707106781186547500, TOL);
    }
    function testSin4() public {
        assertApproxEq(trig.sin(PI / 2), 1e18, TOL);
    }
    function testSin5() public {
        assertApproxEq(trig.sin(PI * 3 / 4), 707106781186547600, TOL);
    }
    function testSin6() public {
        assertApproxEq(trig.sin(PI), 0, TOL);
    }
    function testSin7() public {
        assertApproxEq(trig.sin(PI * 5 / 4), -707106781186547600, TOL);
    }
    function testSin8() public {
        assertApproxEq(trig.sin(PI * 3 / 2), -1e18, TOL);
    }
    function testSin9() public {
        assertApproxEq(trig.sin(PI * 7 / 4), -707106781186547600, TOL);
    }
    function testSin10() public {
        assertApproxEq(trig.sin(PI * 2), 0, TOL);
    }

    // --- Angles above 2π that must be wrapped ---
    function testSin11() public {
        assertApproxEq(trig.sin(SCALE + 0), 0, TOL);
    }
    function testSin12() public {
        assertApproxEq(trig.sin(SCALE + PI / 8), 382683432365089800, TOL);
    }
    function testSin13() public {
        assertApproxEq(trig.sin(SCALE + PI / 4), 707106781186547500, TOL);
    }
    function testSin14() public {
        assertApproxEq(trig.sin(SCALE + PI / 2), 1e18, TOL);
    }
    function testSin15() public {
        assertApproxEq(trig.sin(SCALE + PI * 3 / 4), 707106781186547600, TOL);
    }
    function testSin16() public {
        assertApproxEq(trig.sin(SCALE + PI), 0, TOL);
    }
    function testSin17() public {
        assertApproxEq(trig.sin(SCALE + PI * 5 / 4), -707106781186547600, TOL);
    }
    function testSin18() public {
        assertApproxEq(trig.sin(SCALE + PI * 3 / 2), -1e18, TOL);
    }
    function testSin19() public {
        assertApproxEq(trig.sin(SCALE + PI * 7 / 4), -707106781186547600, TOL);
    }
    function testSin20() public {
        assertApproxEq(trig.sin(SCALE + PI * 2), 0, TOL);
    }

    ////////////////////////////////////////////////////////////////
    //                           COSINE                           //
    ////////////////////////////////////////////////////////////////

    function testNoRevertsCos(uint256 _angle) public view {
        trig.cos(_angle);
    }

    // --- Angles between 0 <= x <= 2π ---
    function testCos1() public {
        assertApproxEq(trig.cos(0), 1e18, TOL);
    }
    function testCos2() public {
        assertApproxEq(trig.cos(PI / 8), 923879532511286756, TOL);
    }
    function testCos3() public {
        assertApproxEq(trig.cos(PI / 4), 707106781186547600, TOL);
    }
    function testCos4() public {
        assertApproxEq(trig.cos(PI / 2), 0, TOL);
    }
    function testCos5() public {
        assertApproxEq(trig.cos(PI * 3 / 4), -707106781186547600, TOL);
    }
    function testCos6() public {
        assertApproxEq(trig.cos(PI), -1e18, TOL);
    }
    function testCos7() public {
        assertApproxEq(trig.cos(PI * 5 / 4), -707106781186547600, TOL);
    }
    function testCos8() public {
        assertApproxEq(trig.cos(PI * 3 / 2), 0, TOL);
    }
    function testCos9() public {
        assertApproxEq(trig.cos(PI * 7 / 4), 707106781186547600, TOL);
    }
    function testCos10() public {
        assertApproxEq(trig.cos(PI * 2), 1e18, TOL);
    }

    // --- Angles above 2π that must be wrapped ---
    function testCos11() public {
        assertApproxEq(trig.cos(SCALE + 0), 1e18, TOL);
    }
    function testCos12() public {
        assertApproxEq(trig.cos(SCALE + PI / 8), 923879532511286756, TOL);
    }
    function testCos13() public {
        assertApproxEq(trig.cos(SCALE + PI / 4), 707106781186547600, TOL);
    }
    function testCos14() public {
        assertApproxEq(trig.cos(SCALE + PI / 2), 0, TOL);
    }
    function testCos15() public {
        assertApproxEq(trig.cos(SCALE + PI * 3 / 4), -707106781186547600, TOL);
    }
    function testCos16() public {
        assertApproxEq(trig.cos(SCALE + PI), -1e18, TOL);
    }
    function testCos17() public {
        assertApproxEq(trig.cos(SCALE + PI * 5 / 4), -707106781186547600, TOL);
    }
    function testCos18() public {
        assertApproxEq(trig.cos(SCALE + PI * 3 / 2), 0, TOL);
    }
    function testCos19() public {
        assertApproxEq(trig.cos(SCALE + PI * 7 / 4), 707106781186547600, TOL);
    }
    function testCos20() public {
        assertApproxEq(trig.cos(SCALE + PI * 2), 1e18, TOL);
    }

    ////////////////////////////////////////////////////////////////
    //                         DSTESTPLUS                         //
    ////////////////////////////////////////////////////////////////

    function abs(int256 a) internal pure returns (int256) {
        return a >= 0 ? a : -a;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function assertApproxEq(int256 a, int256 b, uint256 tol) internal virtual {
        // tol is a wad where 1e18 = 100%, and represents the maximum acceptable percentage tolerance
        // https://www.mathworks.com/matlabcentral/answers/26743-absolute-and-relative-tolerance-definitions
        if (a == b) return;

        if ((a < 0 && b > 0) || (a > 0 && b < 0)) {
        emit log("Error: a ~= b not satisfied, sign mismatch [uint]");
            emit log_named_int("    Expected", a);
            emit log_named_int("      Actual", b);
            fail();
            return;
        }

        uint256 relativeErr = uint256(1e18 * abs(a-b) / min(abs(a), abs(b)));
        if (relativeErr > tol) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_int("    Expected", a);
            emit log_named_int("      Actual", b);
            emit log_named_uint(" Max % Delta", tol);
            emit log_named_uint("     % Delta", relativeErr);
            fail();
        }
    }
}