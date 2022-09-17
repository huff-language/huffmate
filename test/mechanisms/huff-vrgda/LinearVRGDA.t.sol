// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import {
    wadLn,
    toWadUnsafe,
    fromDaysWadUnsafe,
    toDaysWadUnsafe
} from "./utils/SignedWadMath.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";


import "foundry-huff/HuffDeployer.sol";

uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;
uint256 constant MAX_SELLABLE = 6392;

interface MockLinearVRGDA {
    function getTargetSaleTime(int256 sold) external view returns (int256);
    function targetPrice() external view returns (int256);
    function perTimeUnit() external view returns (int256);

    // needed to test - TODO: remove
    function decayConstant() external view returns (int256);

    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) external view returns (uint256);
}

contract LinearVRGDATest is Test {
    MockLinearVRGDA vrgda;

    // Required to sanity check huff deployer
    int256 targetPrice;
    int256 decayConstant;
    int256 perTimeUnit;

    function setUp() public {
        // setup parameters
        targetPrice = 69.42e18;
        int256 priceDecayPercent = 0.31e18;
        perTimeUnit = 2e18;

        // calculate the decay constant
        decayConstant = wadLn(1e18 - priceDecayPercent);
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");

        // Overwrite inlined constants using the huff compiler - essentially equivalent to an immutable
        string memory vrgda_wrapper = vm.readFile("test/mechanisms/huff-vrgda/mocks/LinearVRGDAWrappers.huff");
        vrgda = MockLinearVRGDA(HuffDeployer
            .config()
            .with_code(vrgda_wrapper)
            .with_bytes32_constant("TARGET_PRICE", bytes32(abi.encodePacked(targetPrice)))
            .with_bytes32_constant("DECAY_CONSTANT", bytes32(abi.encodePacked(decayConstant)))
            .with_bytes32_constant("PER_TIME_UNIT", bytes32(abi.encodePacked(perTimeUnit)))
            .deploy("mechanisms/huff-vrgda/LinearVRGDA")
        );
    }

    // Assert that the huff deployer has overriden constants correctly
    function testConstantsOverride() public {
        assertEq(vrgda.targetPrice(), targetPrice);
        assertEq(vrgda.decayConstant(), decayConstant);
        assertEq(vrgda.perTimeUnit(), perTimeUnit);
    }

    function testTargetPrice() public {
        // Warp to the target sale time so that the VRGDA price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(vrgda.getTargetSaleTime(1e18)));

        uint256 cost = vrgda.getVRGDAPrice(toDaysWadUnsafe(block.timestamp), 0);
        assertEq(cost / 0.00001e18, uint256(vrgda.targetPrice()) / 0.00001e18);
    }

    function testPricingBasic() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 239;

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getVRGDAPrice(toDaysWadUnsafe(block.timestamp), numMint);
        assertEq(cost / 0.00001e18, uint256(vrgda.targetPrice()) / 0.00001e18);
    }

    function testAlwaysTargetPriceInRightConditions(uint256 sold) public {
        sold = bound(sold, 0, type(uint128).max);

        assertEq(
            vrgda.getVRGDAPrice(vrgda.getTargetSaleTime(toWadUnsafe(sold + 1)), sold) / 0.00001e18,
            uint256(vrgda.targetPrice()) / 0.00001e18
        );
    }
}