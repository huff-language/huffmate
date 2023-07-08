
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {toWadUnsafe, toDaysWadUnsafe, fromDaysWadUnsafe, wadLn} from "./utils/SignedWadMath.sol";

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";


uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

uint256 constant MAX_SELLABLE = 6392;

interface MockLogisticVRGDA {
    function getTargetSaleTime(int256 sold) external view returns (int256);
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) external view returns (uint256);

    function targetPrice() external view returns (int256);
    function timeScale() external view returns (int256);
    function decayConstant() external view returns (int256);
    function logisticLimit() external view returns(int256);
    function logisticLimitDoubled() external view returns(int256);
}


contract LogisticVRGDATest is Test {
// contract LogisticVRGDATest is Test {
    MockLogisticVRGDA vrgda;

    // constant overrides
    int256 targetPrice;
    int256 decayConstant;

    int256 logisticLimit;
    int256 logisticLimitDoubled;
    int256 timeScale;

    function setUp() public {
        // used to calculate decay constant
        int256 priceDecayPercent = 0.31e18;

        int256 wadMaxSellable = toWadUnsafe(MAX_SELLABLE);
        targetPrice = 69.42e18;
        logisticLimit = int256(wadMaxSellable + 1e18);
        logisticLimitDoubled = int256(wadMaxSellable * 2e18);
        timeScale = 0.0023e18;

        // calculate the decay constant
        decayConstant = wadLn(1e18 - priceDecayPercent);
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");

        // Overwrite inlined constants using the huff compiler - essentially equivalent to an immutable
        string memory vrgda_wrapper = vm.readFile("test/mechanisms/huff-vrgda/mocks/LogisticVRGDAWrappers.huff");
        vrgda = MockLogisticVRGDA(HuffDeployer
            .config()
            .with_code(vrgda_wrapper)
            .with_bytes32_constant("TARGET_PRICE", bytes32(abi.encodePacked(targetPrice)))
            .with_bytes32_constant("DECAY_CONSTANT", bytes32(abi.encodePacked(decayConstant)))
            .with_bytes32_constant("LOGISTIC_LIMIT", bytes32(abi.encodePacked(logisticLimit)))
            .with_bytes32_constant("LOGISTIC_LIMIT_DOUBLED", bytes32(abi.encodePacked(logisticLimitDoubled)))
            .with_bytes32_constant("TIME_SCALE", bytes32(abi.encodePacked(timeScale)))
            .deploy("mechanisms/huff-vrgda/LogisticVRGDA")
        );
    }

    function testConstOverrides() public {
        assert(vrgda.targetPrice() == targetPrice);
        assert(vrgda.decayConstant() == decayConstant);
        assert(vrgda.timeScale() == timeScale);
        assert(vrgda.logisticLimit() == logisticLimit);
        assert(vrgda.logisticLimitDoubled() == logisticLimitDoubled);
    }

    function testTargetPrice() public {
        // Warp to the target sale time so that the VRGDA price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(vrgda.getTargetSaleTime(1e18)));

        uint256 cost = vrgda.getVRGDAPrice(toDaysWadUnsafe(block.timestamp), 0);
        assertEq(cost / 0.0000001e18, uint256(vrgda.targetPrice()) / 0.0000001e18);
    }

    function testPricingBasic() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 876;

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getVRGDAPrice(toDaysWadUnsafe(block.timestamp), numMint);

        // Equal within 2 percent since num mint is rounded from true decimal amount.
        assertEq(cost / 0.02e18, uint256(vrgda.targetPrice()) / 0.02e18);
    }

    function testGetTargetSaleTimeDoesNotRevertEarly() public view {
        vrgda.getTargetSaleTime(toWadUnsafe(MAX_SELLABLE));
    }


    function testNoOverflowForMostTokens(uint256 timeSinceStart, uint256 sold) public {
        vrgda.getVRGDAPrice(int256(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS * 1e18)), bound(sold, 0, 1730));
    }

    function testNoOverflowForAllTokens(uint256 timeSinceStart, uint256 sold) public {
        vrgda.getVRGDAPrice(
            int256(bound(timeSinceStart, 3870 days * 1e18, ONE_THOUSAND_YEARS * 1e18)),
            bound(sold, 0, 6391)
        );
    }

    function testAlwaysTargetPriceInRightConditions(uint256 sold) public {
        sold = bound(sold, 0, MAX_SELLABLE - 1);

        assertEq(
            vrgda.getVRGDAPrice(vrgda.getTargetSaleTime(toWadUnsafe(sold + 1)), sold) / 0.00001e18,
            uint256(vrgda.targetPrice()) / 0.00001e18
        );
    }
}