// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IFixedPointMath {
    function mulDivDown(uint256,uint256,uint256) external pure returns(uint256);
    function mulDivUp(uint256,uint256,uint256) external pure returns(uint256);
    function mulWadDown(uint256,uint256) external pure returns(uint256);
    function mulWadUp(uint256,uint256) external pure returns(uint256);
    function divWadDown(uint256,uint256) external pure returns(uint256);
    function divWadUp(uint256,uint256) external pure returns(uint256);
    function rpow(uint256,uint256,uint256) external pure returns(uint256);
    function expWad(int256) external pure returns(int256);
    function lnWad(int256) external pure returns(int256);
    function powWad(int256,int256) external pure returns(int256);
    function sqrt(uint256) external pure returns(uint256);
    function log2(uint256) external pure returns(uint256);
    function cbrt(uint256) external pure returns(uint256);
}

contract FixedPointMathTest is Test {
    IFixedPointMath math;

    function setUp() public {
        /// @notice deploy a new instance of IFixedPointMath by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/math/mocks/FixedPointMathWrappers.huff");
        math = IFixedPointMath(HuffDeployer.deploy_with_code("math/FixedPointMath", wrapper_code));
    }

    function testExpWad() public {
        assertEq(math.expWad(-42139678854452767551), 0);

        assertEq(math.expWad(-3e18), 49787068367863942);
        assertEq(math.expWad(-2e18), 135335283236612691);
        assertEq(math.expWad(-1e18), 367879441171442321);

        assertEq(math.expWad(-0.5e18), 606530659712633423);
        assertEq(math.expWad(-0.3e18), 740818220681717866);

        assertEq(math.expWad(0), 1000000000000000000);

        assertEq(math.expWad(0.3e18), 1349858807576003103);
        assertEq(math.expWad(0.5e18), 1648721270700128146);

        assertEq(math.expWad(1e18), 2718281828459045235);
        assertEq(math.expWad(2e18), 7389056098930650227);
        assertEq(
            math.expWad(3e18),
            20085536923187667741
            // True value: 20085536923187667740.92
        );

        assertEq(
            math.expWad(10e18),
            220264657948067165169_80
            // True value: 22026465794806716516957.90
            // Relative error 9.987984547746668e-22
        );

        assertEq(
            math.expWad(50e18),
            5184705528587072464_148529318587763226117
            // True value: 5184705528587072464_087453322933485384827.47
            // Relative error: 1.1780031733243328e-20
        );

        assertEq(
            math.expWad(100e18),
            268811714181613544841_34666106240937146178367581647816351662017
            // True value: 268811714181613544841_26255515800135873611118773741922415191608
            // Relative error: 3.128803544297531e-22
        );

        assertEq(
            math.expWad(135305999368893231588),
            578960446186580976_50144101621524338577433870140581303254786265309376407432913
            // True value: 578960446186580976_49816762928942336782129491980154662247847962410455084893091
            // Relative error: 5.653904247484822e-21
        );
    }

    function testPowWad() public {
        assertEq(math.powWad(1, 8), 999999999999999669);
        assertEq(math.powWad(2, 1e18), 1);
        assertEq(math.powWad(2e27, 4e18), 15999999999999999962947398429798144256963724914467878199);
        assertEq(math.powWad(4e36, 9e9), 1000000385495508618);
    }

    function testMulWadDown() public {
        assertEq(math.mulWadDown(2.5e18, 0.5e18), 1.25e18);
        assertEq(math.mulWadDown(3e18, 1e18), 3e18);
        assertEq(math.mulWadDown(369, 271), 0);
    }

    function testMulWadDownEdgeCases() public {
        assertEq(math.mulWadDown(0, 1e18), 0);
        assertEq(math.mulWadDown(1e18, 0), 0);
        assertEq(math.mulWadDown(0, 0), 0);
    }

    function testMulWadUp() public {
        assertEq(math.mulWadUp(2.5e18, 0.5e18), 1.25e18);
        assertEq(math.mulWadUp(3e18, 1e18), 3e18);
        assertEq(math.mulWadUp(369, 271), 1);
    }

    function testMulWadUpEdgeCases() public {
        assertEq(math.mulWadUp(0, 1e18), 0);
        assertEq(math.mulWadUp(1e18, 0), 0);
        assertEq(math.mulWadUp(0, 0), 0);
    }

    function testDivWadDown() public {
        assertEq(math.divWadDown(1.25e18, 0.5e18), 2.5e18);
        assertEq(math.divWadDown(3e18, 1e18), 3e18);
        assertEq(math.divWadDown(2, 100000000000000e18), 0);
    }

    function testDivWadDownEdgeCases() public {
        assertEq(math.divWadDown(0, 1e18), 0);
    }

    function testFailDivWadDownZeroDenominator() public {
        math.divWadDown(1e18, 0);
    }

    function testDivWadUp() public {
        assertEq(math.divWadUp(1.25e18, 0.5e18), 2.5e18);
        assertEq(math.divWadUp(3e18, 1e18), 3e18);
        assertEq(math.divWadUp(2, 100000000000000e18), 1);
    }

    function testDivWadUpEdgeCases() public {
        assertEq(math.divWadUp(0, 1e18), 0);
    }

    function testFailDivWadUpZeroDenominator() public {
        math.divWadUp(1e18, 0);
    }

    function testMulDivDown() public {
        assertEq(math.mulDivDown(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(math.mulDivDown(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(math.mulDivDown(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(math.mulDivDown(369, 271, 1e2), 999);

        assertEq(math.mulDivDown(1e27, 1e27, 2e27), 0.5e27);
        assertEq(math.mulDivDown(1e18, 1e18, 2e18), 0.5e18);
        assertEq(math.mulDivDown(1e8, 1e8, 2e8), 0.5e8);

        assertEq(math.mulDivDown(2e27, 3e27, 2e27), 3e27);
        assertEq(math.mulDivDown(3e18, 2e18, 3e18), 2e18);
        assertEq(math.mulDivDown(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivDownEdgeCases() public {
        assertEq(math.mulDivDown(0, 1e18, 1e18), 0);
        assertEq(math.mulDivDown(1e18, 0, 1e18), 0);
        assertEq(math.mulDivDown(0, 0, 1e18), 0);
    }

    function testFailMulDivDownZeroDenominator() public {
        math.mulDivDown(1e18, 1e18, 0);
    }

    function testMulDivUp() public {
        assertEq(math.mulDivUp(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(math.mulDivUp(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(math.mulDivUp(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(math.mulDivUp(369, 271, 1e2), 1000);

        assertEq(math.mulDivUp(1e27, 1e27, 2e27), 0.5e27);
        assertEq(math.mulDivUp(1e18, 1e18, 2e18), 0.5e18);
        assertEq(math.mulDivUp(1e8, 1e8, 2e8), 0.5e8);

        assertEq(math.mulDivUp(2e27, 3e27, 2e27), 3e27);
        assertEq(math.mulDivUp(3e18, 2e18, 3e18), 2e18);
        assertEq(math.mulDivUp(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivUpEdgeCases() public {
        assertEq(math.mulDivUp(0, 1e18, 1e18), 0);
        assertEq(math.mulDivUp(1e18, 0, 1e18), 0);
        assertEq(math.mulDivUp(0, 0, 1e18), 0);
    }

    function testFailMulDivUpZeroDenominator() public {
        math.mulDivUp(1e18, 1e18, 0);
    }

    function testLnWad() public {
        assertEq(math.lnWad(1e18), 0);

        // Actual: 999999999999999999.8674576…
        assertEq(math.lnWad(2718281828459045235), 999999999999999999);

        // Actual: 2461607324344817917.963296…
        assertEq(math.lnWad(11723640096265400935), 2461607324344817918);
    }

    function testLnWadSmall() public {
        // Actual: -41446531673892822312.3238461…
        assertEq(math.lnWad(1), -41446531673892822313);

        // Actual: -37708862055609454006.40601608…
        assertEq(math.lnWad(42), -37708862055609454007);

        // Actual: -32236191301916639576.251880365581…
        assertEq(math.lnWad(1e4), -32236191301916639577);

        // Actual: -20723265836946411156.161923092…
        assertEq(math.lnWad(1e9), -20723265836946411157);
    }

    function testLnWadBig() public {
        // Actual: 135305999368893231589.070344787…
        assertEq(math.lnWad(2**255 - 1), 135305999368893231589);

        // Actual: 76388489021297880288.605614463571…
        assertEq(math.lnWad(2**170), 76388489021297880288);

        // Actual: 47276307437780177293.081865…
        assertEq(math.lnWad(2**128), 47276307437780177293);
    }

    function testLnWadNegative() public {
        // TODO: Blocked on <https://github.com/gakonst/foundry/issues/864>
        // hevm.expectRevert(math.LnNegativeUndefined.selector);
        // math.lnWad(-1);
        // math.lnWad(-2**255);
    }

    function testLnWadOverflow() public {
        // TODO: Blocked on <https://github.com/gakonst/foundry/issues/864>
        // hevm.expectRevert(math.Overflow.selector);
        // math.lnWad(0);
    }

    function testRPow() public {
        assertEq(math.rpow(2e27, 2, 1e27), 4e27);
        assertEq(math.rpow(2e18, 2, 1e18), 4e18);
        assertEq(math.rpow(2e8, 2, 1e8), 4e8);
        assertEq(math.rpow(8, 3, 1), 512);
        assertEq(math.rpow(0, 0, 1e18), 1e18);
        assertEq(math.rpow(0, 1, 1), 0);
    }

    function testSqrt() public {
        assertEq(math.sqrt(0), 0);
        assertEq(math.sqrt(1), 1);
        assertEq(math.sqrt(2704), 52);
        assertEq(math.sqrt(110889), 333);
        assertEq(math.sqrt(32239684), 5678);
    }

    function testLog2() public {
        assertEq(math.log2(2), 1);
        assertEq(math.log2(4), 2);
        assertEq(math.log2(1024), 10);
        assertEq(math.log2(1048576), 20);
        assertEq(math.log2(1073741824), 30);
    }

    function testCbrt() public {
        assertEq(math.cbrt(0), 0);
        assertEq(math.cbrt(1), 1);
        assertEq(math.cbrt(2), 1);
        assertEq(math.cbrt(3), 1);
        assertEq(math.cbrt(9), 2);
        assertEq(math.cbrt(27), 3);
        assertEq(math.cbrt(80), 4);
        assertEq(math.cbrt(81), 4);
        assertEq(math.cbrt(10 ** 18), 10 ** 6);
        assertEq(math.cbrt(8 * 10 ** 18), 2 * 10 ** 6);
        assertEq(math.cbrt(9 * 10 ** 18), 2080083);
        assertEq(math.cbrt(type(uint8).max), 6);
        assertEq(math.cbrt(type(uint16).max), 40);
        assertEq(math.cbrt(type(uint32).max), 1625);
        assertEq(math.cbrt(type(uint64).max), 2642245);
        assertEq(math.cbrt(type(uint128).max), 6981463658331);
        assertEq(math.cbrt(type(uint256).max), 48740834812604276470692694);
    }


    function testFuzzMulWadDown(uint256 x, uint256 y) public {
        // Ignore cases where x * y overflows.
        unchecked {
            if (x != 0 && (x * y) / x != y) return;
        }

        assertEq(math.mulWadDown(x, y), (x * y) / 1e18);
    }

    function testFailFuzzMulWadDownOverflow(uint256 x, uint256 y) public {
        // Ignore cases where x * y does not overflow.
        unchecked {
            if ((x * y) / x == y) revert();
        }

        math.mulWadDown(x, y);
    }

    function testFuzzMulWadUp(uint256 x, uint256 y) public {
        // Ignore cases where x * y overflows.
        unchecked {
            if (x != 0 && (x * y) / x != y) return;
        }

        assertEq(math.mulWadUp(x, y), x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1);
    }

    function testFailFuzzMulWadUpOverflow(uint256 x, uint256 y) public {
        // Ignore cases where x * y does not overflow.
        unchecked {
            if ((x * y) / x == y) revert();
        }

        math.mulWadUp(x, y);
    }

    function testFuzzDivWadDown(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD overflows or y is 0.
        unchecked {
            if (y == 0 || (x != 0 && (x * 1e18) / 1e18 != x)) return;
        }

        assertEq(math.divWadDown(x, y), (x * 1e18) / y);
    }

    function testFailFuzzDivWadDownOverflow(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD does not overflow or y is 0.
        unchecked {
            if (y == 0 || (x * 1e18) / 1e18 == x) revert();
        }

        math.divWadDown(x, y);
    }

    function testFailFuzzDivWadDownZeroDenominator(uint256 x) public {
        math.divWadDown(x, 0);
    }

    function testFuzzDivWadUp(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD overflows or y is 0.
        unchecked {
            if (y == 0 || (x != 0 && (x * 1e18) / 1e18 != x)) return;
        }

        assertEq(math.divWadUp(x, y), x == 0 ? 0 : (x * 1e18 - 1) / y + 1);
    }

    function testFailFuzzDivWadUpOverflow(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD does not overflow or y is 0.
        unchecked {
            if (y == 0 || (x * 1e18) / 1e18 == x) revert();
        }

        math.divWadUp(x, y);
    }

    function testFailFuzzDivWadUpZeroDenominator(uint256 x) public {
        math.divWadUp(x, 0);
    }

    function testFuzzMulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(math.mulDivDown(x, y, denominator), (x * y) / denominator);
    }

    function testFailFuzzMulDivDownOverflow(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            if (denominator == 0 || (x * y) / x == y) revert();
        }

        math.mulDivDown(x, y, denominator);
    }

    function testFailFuzzMulDivDownZeroDenominator(uint256 x, uint256 y) public {
        math.mulDivDown(x, y, 0);
    }

    function testFuzzMulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(math.mulDivUp(x, y, denominator), x * y == 0 ? 0 : (x * y - 1) / denominator + 1);
    }

    function testFailFuzzMulDivUpOverflow(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            if (denominator == 0 || (x * y) / x == y) revert();
        }

        math.mulDivUp(x, y, denominator);
    }

    function testFailFuzzMulDivUpZeroDenominator(uint256 x, uint256 y) public {
        math.mulDivUp(x, y, 0);
    }

    function testFuzzSqrt(uint256 x) public {
        uint256 root = math.sqrt(x);
        uint256 next = root + 1;

        // Ignore cases where next * next overflows.
        unchecked {
            if (next * next < next) return;
        }

        assertTrue(root * root <= x && next * next > x);
    }

    function testFuzzCbrt(uint256 x) public {
        uint256 result = math.cbrt(x);
        assertEq(result, cbrt(x));
    }

    function testFuzzLog2() public {
        for (uint256 i = 1; i < 255; i++) {
            assertEq(math.log2((1 << i) - 1), i - 1);
            assertEq(math.log2((1 << i)), i);
            assertEq(math.log2((1 << i) + 1), i);
        }
    }

    /// Solady: https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := shl(add(div(r, 3), lt(0xf, shr(r, x))), 0xff)
            z := div(z, byte(mod(r, 3), shl(232, 0x7f624b)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }
}
