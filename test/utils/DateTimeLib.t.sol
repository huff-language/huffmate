// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

interface IDateTimeLib {
    function weekday(uint256 timestamp) external view returns (uint256 result);
    function isLeapYear(uint256 year) external view returns (bool result);
    function daysInMonth(uint256 year, uint256 month) external view returns (uint256 result);
    function dateToEpochDay(uint256 year, uint256 month, uint256 day) external view returns (uint256 result);
    function epochDayToDate(uint256 epochDay) external view returns (uint256 year, uint256 month, uint256 day);
    function timestampToDate(uint256 timestamp) external view returns (uint256 year, uint256 month, uint256 day);
    function dateToTimestamp(uint256 year, uint256 month, uint256 day) external view returns (uint256 result);
    function dateTimeToTimestamp(uint256 year,uint256 month, uint256 day, uint256 hour, uint256 mins, uint256 secs) external view returns (uint256 result);
    function nthWeekdayInMonthOfYearTimestamp(uint256 wd, uint256 n, uint256 year, uint256 month) external view returns (uint256 result);
}

contract DateTimeLibTest is Test {
    struct DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
    }
    uint256 internal constant MON = 1;
    uint256 internal constant TUE = 2;
    uint256 internal constant WED = 3;
    uint256 internal constant THU = 4;
    uint256 internal constant FRI = 5;
    uint256 internal constant SAT = 6;
    uint256 internal constant SUN = 7;

    // Months and days of months are 1-indexed for ease of use.

    uint256 internal constant JAN = 1;
    uint256 internal constant FEB = 2;
    uint256 internal constant MAR = 3;
    uint256 internal constant APR = 4;
    uint256 internal constant MAY = 5;
    uint256 internal constant JUN = 6;
    uint256 internal constant JUL = 7;
    uint256 internal constant AUG = 8;
    uint256 internal constant SEP = 9;
    uint256 internal constant OCT = 10;
    uint256 internal constant NOV = 11;
    uint256 internal constant DEC = 12;

    // These limits are large enough for most practical purposes.
    // Inputs that exceed these limits result in undefined behavior.

    uint256 internal constant MAX_SUPPORTED_YEAR = 0xffffffff;
    uint256 internal constant MAX_SUPPORTED_EPOCH_DAY = 0x16d3e098039;
    uint256 internal constant MAX_SUPPORTED_TIMESTAMP = 0x1e18549868c76ff;
    /// @dev Address of the DateTimeLib contract.
    IDateTimeLib public sut;

    /// @dev Setup the testing environment.
    function setUp() public {
        string memory wrapper_code = vm.readFile(
            "test/utils/mocks/DateTimeLibWrappers.huff"
        );
        sut = IDateTimeLib(
            HuffDeployer.deploy_with_code("utils/DateTimeLib", wrapper_code)
        );
    }

    function testWeekday() public {
        assertEq(sut.weekday(1), 4);
        assertEq(sut.weekday(86400), 5);
        assertEq(sut.weekday(86401), 5);
        assertEq(sut.weekday(172800), 6);
        assertEq(sut.weekday(259200), 7);
        assertEq(sut.weekday(345600), 1);
        assertEq(sut.weekday(432000), 2);
        assertEq(sut.weekday(518400), 3);
    }

    function testFuzzWeekday(uint256 timestamp) public {
        timestamp = timestamp % 10 ** 10;
        uint256 weekday = ((timestamp / 86400 + 3) % 7) + 1;
        assertEq(weekday, sut.weekday(timestamp));
    }

    function testIsLeapYear() public {
        assertTrue(sut.isLeapYear(2000));
        assertTrue(sut.isLeapYear(2024));
        assertTrue(sut.isLeapYear(2048));
        assertTrue(sut.isLeapYear(2072));
        assertTrue(sut.isLeapYear(2104));
        assertTrue(sut.isLeapYear(2128));
        assertTrue(sut.isLeapYear(10032));
        assertTrue(sut.isLeapYear(10124));
        assertTrue(sut.isLeapYear(10296));
        assertTrue(sut.isLeapYear(10400));
        assertTrue(sut.isLeapYear(10916));
    }

    function testFuzzIsLeapYear(uint256 year) public {
        assertEq(
            sut.isLeapYear(year),
            (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0)
        );
    }

    function testDaysInMonth() public {
        assertEq(sut.daysInMonth(2022, 1), 31);
        assertEq(sut.daysInMonth(2022, 2), 28);
        assertEq(sut.daysInMonth(2022, 3), 31);
        assertEq(sut.daysInMonth(2022, 4), 30);
        assertEq(sut.daysInMonth(2022, 5), 31);
        assertEq(sut.daysInMonth(2022, 6), 30);
        assertEq(sut.daysInMonth(2022, 7), 31);
        assertEq(sut.daysInMonth(2022, 8), 31);
        assertEq(sut.daysInMonth(2022, 9), 30);
        assertEq(sut.daysInMonth(2022, 10), 31);
        assertEq(sut.daysInMonth(2022, 11), 30);
        assertEq(sut.daysInMonth(2022, 12), 31);
        assertEq(sut.daysInMonth(2024, 1), 31);
        assertEq(sut.daysInMonth(2024, 2), 29);
        assertEq(sut.daysInMonth(1900, 2), 28);
    }

    function testDateToEpochDay() public {
        assertEq(sut.dateToEpochDay(1970, 1, 1), 0);
        assertEq(sut.dateToEpochDay(1970, 1, 2), 1);
        assertEq(sut.dateToEpochDay(1970, 2, 1), 31);
        assertEq(sut.dateToEpochDay(1970, 3, 1), 59);
        assertEq(sut.dateToEpochDay(1970, 4, 1), 90);
        assertEq(sut.dateToEpochDay(1970, 5, 1), 120);
        assertEq(sut.dateToEpochDay(1970, 6, 1), 151);
        assertEq(sut.dateToEpochDay(1970, 7, 1), 181);
        assertEq(sut.dateToEpochDay(1970, 8, 1), 212);
        assertEq(sut.dateToEpochDay(1970, 9, 1), 243);
        assertEq(sut.dateToEpochDay(1970, 10, 1), 273);
        assertEq(sut.dateToEpochDay(1970, 11, 1), 304);
        assertEq(sut.dateToEpochDay(1970, 12, 1), 334);
        assertEq(sut.dateToEpochDay(1970, 12, 31), 364);
        assertEq(sut.dateToEpochDay(1971, 1, 1), 365);
        assertEq(sut.dateToEpochDay(1980, 11, 3), 3959);
        assertEq(sut.dateToEpochDay(2000, 3, 1), 11017);
        assertEq(sut.dateToEpochDay(2355, 12, 31), 140982);
        assertEq(sut.dateToEpochDay(99999, 12, 31), 35804721);
        assertEq(sut.dateToEpochDay(100000, 12, 31), 35805087);
        assertEq(sut.dateToEpochDay(604800, 2, 29), 220179195);
        assertEq(sut.dateToEpochDay(1667347200, 2, 29), 608985340227);
        assertEq(sut.dateToEpochDay(1667952000, 2, 29), 609206238891);
    }

    function testDaysInMonth(uint256 year, uint256 month) public {
        month = bound(month, 1, 12);
        if (sut.isLeapYear(year) && month == 2) {
            assertEq(sut.daysInMonth(year, month), 29);
        } else if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            assertEq(sut.daysInMonth(year, month), 31);
        } else if (month == 2) {
            assertEq(sut.daysInMonth(year, month), 28);
        } else {
            assertEq(sut.daysInMonth(year, month), 30);
        }
    }

    // prettier-ignore
    function testNthWeekdayInMonthOfYearTimestamp() public {
        uint256 wd;
        // 1st 2nd 3rd 4th monday in Novermber 2022.
        wd = MON;
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, wd),1667779200);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, wd), 1668384000);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, wd), 1668988800);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, wd), 1669593600);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, wd), 0);

        // 1st... 5th Wednesday in Novermber 2022.
        wd = WED;
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, wd), 1667347200);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, wd), 1667952000);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, wd), 1668556800);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, wd), 1669161600);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, wd), 1669766400);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 11, 6, wd), 0);

        // 1st... 5th Friday in December 2022.
        wd = FRI;
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 1, wd), 1669939200);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 2, wd), 1670544000);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 3, wd), 1671148800);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 4, wd), 1671753600);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 5, wd), 1672358400);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2022, 12, 6, wd), 0);

        // 1st... 5th Sunday in January 2023.
        wd = SUN;
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 1, wd), 1672531200);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 2, wd), 1673136000);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 3, wd), 1673740800);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 4, wd), 1674345600);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 5, wd), 1674950400);
        assertEq(sut.nthWeekdayInMonthOfYearTimestamp(2023, 1, 6, wd), 0);
    }

    function testEpochDaysToDate() public {
        DateTime memory d;
        (d.year, d.month, d.day) = sut.epochDayToDate(0);
        assertTrue(d.year == 1970 && d.month == 1 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(31);
        assertTrue(d.year == 1970 && d.month == 2 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(59);
        assertTrue(d.year == 1970 && d.month == 3 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(90);
        assertTrue(d.year == 1970 && d.month == 4 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(120);
        assertTrue(d.year == 1970 && d.month == 5 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(151);
        assertTrue(d.year == 1970 && d.month == 6 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(181);
        assertTrue(d.year == 1970 && d.month == 7 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(212);
        assertTrue(d.year == 1970 && d.month == 8 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(243);
        assertTrue(d.year == 1970 && d.month == 9 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(273);
        assertTrue(d.year == 1970 && d.month == 10 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(304);
        assertTrue(d.year == 1970 && d.month == 11 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(334);
        assertTrue(d.year == 1970 && d.month == 12 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(365);
        assertTrue(d.year == 1971 && d.month == 1 && d.day == 1);
        (d.year, d.month, d.day) = sut.epochDayToDate(10987);
        assertTrue(d.year == 2000 && d.month == 1 && d.day == 31);
        (d.year, d.month, d.day) = sut.epochDayToDate(18321);
        assertTrue(d.year == 2020 && d.month == 2 && d.day == 29);
        (d.year, d.month, d.day) = sut.epochDayToDate(156468);
        assertTrue(d.year == 2398 && d.month == 5 && d.day == 25);
        (d.year, d.month, d.day) = sut.epochDayToDate(35805087);
        assertTrue(d.year == 100000 && d.month == 12 && d.day == 31);
    }

    function testEpochDayToDate(uint256 epochDay) public {
        // TODO: Need to check why it randomly fails on certain inputs
        DateTime memory d;
        (d.year, d.month, d.day) = sut.epochDayToDate(epochDay);
        assertEq(
            epochDay,
            sut.dateToEpochDay(d.year, d.month, d.day),
            "ValidateEpochDay"
        );
    }

    function testDateToAndFroTimestamp() public {
        unchecked {
            for (uint256 i; i < 250; ++i) {
                uint256 year = _bound(_random(), 1970, MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = sut.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
                uint256 timestamp = sut.dateToTimestamp(year, month, day);
                assertEq(
                    timestamp,
                    sut.dateToEpochDay(year, month, day) * 86400
                );
                (uint256 y, uint256 m, uint256 d) = sut.timestampToDate(
                    timestamp
                );

                assertEq(year, y, "year");
                assertEq(month, m, "month");
                assertEq(day, d, "day");
            }
        }
    }

    function testDateToEpochDayGas() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 year = _bound(_random(), 1970, MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = sut.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
                uint256 epochDay = sut.dateToEpochDay(year, month, day);
                sum += epochDay;
            }
            assertTrue(sum != 0);
        }
    }

    function testEpochDayToDateGas2() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 epochDay = _bound(
                    _random(),
                    0,
                    MAX_SUPPORTED_EPOCH_DAY
                );
                (
                    uint256 year,
                    uint256 month,
                    uint256 day
                ) = _epochDayToDateOriginal2(epochDay);
                sum += year + month + day;
            }
            assertTrue(sum != 0);
        }
    }

    function testDateToEpochDayDifferential(DateTime memory d) public {
        d.year = _bound(d.year, 1970, MAX_SUPPORTED_YEAR);
        d.month = _bound(d.month, 1, 12);
        d.day = _bound(d.day, 1, sut.daysInMonth(d.year, d.month));
        uint256 expectedResult = _dateToEpochDayOriginal(
            d.year,
            d.month,
            d.day
        );
        assertEq(sut.dateToEpochDay(d.year, d.month, d.day), expectedResult);
    }

    function testDateToEpochDayDifferential2(DateTime memory d) public {
        d.year = _bound(d.year, 1970, MAX_SUPPORTED_YEAR);
        d.month = _bound(d.month, 1, 12);
        d.day = _bound(d.day, 1, sut.daysInMonth(d.year, d.month));
        uint256 expectedResult = _dateToEpochDayOriginal2(
            d.year,
            d.month,
            d.day
        );
        assertEq(sut.dateToEpochDay(d.year, d.month, d.day), expectedResult);
    }

    function testEpochDayToDateDifferential(uint256 timestamp) public {
        timestamp = _bound(timestamp, 0, MAX_SUPPORTED_TIMESTAMP);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day) = _epochDayToDateOriginal(timestamp);
        (b.year, b.month, b.day) = sut.epochDayToDate(timestamp);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
    }

    function testEpochDayToDateDifferential2(uint256 timestamp) public {
        timestamp = _bound(timestamp, 0, MAX_SUPPORTED_TIMESTAMP);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day) = _epochDayToDateOriginal2(timestamp);
        (b.year, b.month, b.day) = sut.epochDayToDate(timestamp);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
    }

    ////////////////////////////////////////////////////////////////
    //               Internal methods / Helpers                   //
    ////////////////////////////////////////////////////////////////

    function _random() internal returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // This is the keccak256 of a very long string I randomly mashed on my keyboard.
            let
                sSlot
            := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            // Do some biased sampling for more robust tests.
            for {

            } 1 {

            } {
                let d := byte(0, r)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2.
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := xor(
                        not(0),
                        mul(iszero(and(4, d)), not(xor(sValue, r)))
                    )
                    // Set `r` to `t` shifted left or right by a random multiple of 8.
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) {
                            t := 1
                        }
                        r := add(
                            shl(shl(3, and(byte(3, r), 31)), t),
                            sub(and(r, 7), 3)
                        )
                    }
                    default {
                        if iszero(and(16, d)) {
                            t := shl(255, 1)
                        }
                        r := add(
                            shr(shl(3, and(byte(3, r), 31)), t),
                            sub(and(r, 7), 3)
                        )
                    }
                    // With a 1/2 chance, negate `r`.
                    if iszero(and(32, d)) {
                        r := not(r)
                    }
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
        }
    }

    function _bound(
        uint256 x,
        uint256 min,
        uint256 max
    ) internal pure override returns (uint256 result) {
        require(
            min <= max,
            "_bound(uint256,uint256,uint256): Max is less than min."
        );

        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                // If `x` is between `min` and `max`, return `x` directly.
                // This is to ensure that dictionary values
                // do not get shifted if the min is nonzero.
                // More info: https://github.com/foundry-rs/forge-std/issues/188
                if iszero(or(lt(x, min), gt(x, max))) {
                    result := x
                    break
                }

                let size := add(sub(max, min), 1)
                if and(iszero(gt(x, 3)), gt(size, x)) {
                    result := add(min, x)
                    break
                }

                let w := not(0)
                if and(iszero(lt(x, sub(0, 4))), gt(size, sub(w, x))) {
                    result := sub(max, sub(w, x))
                    break
                }

                // Otherwise, wrap x into the range [min, max],
                // i.e. the range is inclusive.
                if iszero(lt(x, max)) {
                    let d := sub(x, max)
                    let r := mod(d, size)
                    if iszero(r) {
                        result := max
                        break
                    }
                    result := add(add(min, r), w)
                    break
                }
                let d := sub(min, x)
                let r := mod(d, size)
                if iszero(r) {
                    result := min
                    break
                }
                result := add(sub(max, r), 1)
                break
            }
        }
    }

    function _dateToEpochDayOriginal(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256) {
        unchecked {
            if (month <= 2) {
                year -= 1;
            }
            uint256 era = year / 400;
            uint256 yoe = year - era * 400;
            uint256 doy = (153 * (month > 2 ? month - 3 : month + 9) + 2) /
                5 +
                day -
                1;
            uint256 doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
            return era * 146097 + doe - 719468;
        }
    }

    function _dateToEpochDayOriginal2(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        unchecked {
            int256 _year = int256(year);
            int256 _month = int256(month);
            int256 _day = int256(day);

            int256 _m = (_month - 14) / 12;
            int256 __days = _day -
                32075 +
                ((1461 * (_year + 4800 + _m)) / 4) +
                ((367 * (_month - 2 - _m * 12)) / 12) -
                ((3 * ((_year + 4900 + _m) / 100)) / 4) -
                2440588;

            _days = uint256(__days);
        }
    }

    function _epochDayToDateOriginal(
        uint256 timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            timestamp += 719468;
            uint256 era = timestamp / 146097;
            uint256 doe = timestamp - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            year = yoe + era * 400;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            day = doy - (153 * mp + 2) / 5 + 1;
            month = mp < 10 ? mp + 3 : mp - 9;
            if (month <= 2) {
                year += 1;
            }
        }
    }

    function _epochDayToDateOriginal2(
        uint256 _days
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + 2440588;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }
}
