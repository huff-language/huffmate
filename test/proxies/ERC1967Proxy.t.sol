// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import { MockERC1155 } from "solmate/test/utils/mocks/MockERC1155.sol";
import { Bytes32AddressLib } from "solmate/utils/Bytes32AddressLib.sol";
import { MockBeacon } from "./mocks/MockBeacon.sol";
import { MockProxiableUUID } from "./mocks/MockProxiableUUID.sol";
import { NotUUPSMockProxiableUUID } from "./mocks/NotUUPSMockProxiableUUID.sol";
import { ERC1155Recipient } from "solmate/test/ERC1155.t.sol";
import {MockReturner} from "./mocks/MockReturner.sol";


interface Proxy {
    // Implementation
    function implementation() external view returns (address);

    // Upgrade
    function upgradeTo(address) external;
    function upgradeToAndCall(address, bytes calldata, bool) external payable;
    function upgradeToAndCallUUPS(address, bytes calldata, bool) external payable;

    // Admin
    function admin() external view returns (address);
    function changeAdmin(address) external;

    // Beacon
    function beacon() external view returns (address);
    function setBeacon(address) external;
    function upgradeBeaconAndCall(address, bytes calldata, bool) external;
}


contract ProxiesTest is Test, ERC1155Recipient {
    using Bytes32AddressLib for bytes32;

    Proxy proxy;
    MockERC1155 implementation;
    MockBeacon beacon;
    NotUUPSMockProxiableUUID notUUPSProxiableUUID;
    MockProxiableUUID proxiableUUID;

    function setUp() public {
        // Deploy a mock contract to use as the implementation
        implementation = new MockERC1155();
        beacon = new MockBeacon(address(implementation));
        proxiableUUID = new MockProxiableUUID();
        notUUPSProxiableUUID = new NotUUPSMockProxiableUUID();

        // Deployment args 
        
        bytes memory args = bytes.concat(
                abi.encode(address(implementation)), 
                abi.encode(string("")), 
                abi.encode(address(this)
            )
        );

        string memory wrapper_code = vm.readFile("test/proxies/mocks/ProxyWrappers.huff");
        proxy = Proxy(HuffDeployer
            .config()
            .with_args(args)
            .with_code(wrapper_code)
            .deploy("proxies/ERC1967Proxy")
        );
    }


    function testAdminSetConstructor() public {
        assertEq(proxy.admin(), address(this));
    }

    function testChangeProxyAdmin() public {
        proxy.changeAdmin(address(0x1));
        assertEq(proxy.admin(), address(0x1));
    }

    function testChangeAdminZeroAddress() public {
        vm.expectRevert("ZERO_ADDRESS");
        proxy.changeAdmin(address(0x0));
    }


    // Beacon
    function testGetBeacon() public {
        assertEq(proxy.beacon(), address(0x0));
    }

    function failSetBeaconIfNotContract() public {
        vm.expectRevert("NOT_CONTRACT");
        proxy.setBeacon(address(0x1));
    }

    function testSetBeacon() public {
        proxy.setBeacon(address(beacon));
        assertEq(proxy.beacon(), address(beacon));
    }

    function testUpgradeBeaconToAndCall() public {
        proxy.upgradeBeaconAndCall(address(beacon), bytes(""), false);
        assertEq(proxy.beacon(), address(beacon));
    }

    function testSetUpgradeTo() public {
        proxy.upgradeTo(address(implementation));
        assertEq(proxy.implementation(), address(implementation));
    }

    function testCannotSetToZeroAddress() public {
        vm.expectRevert("NON_CONTRACT");
        proxy.upgradeTo(address(0x1));
    }

    function testUpgradeToAndCall() public {
        
        // mint calldata
        bytes memory mintCalldata = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(this),
            uint256(1),
            uint256(1),
            bytes("")
        );

        proxy.upgradeToAndCall(address(implementation), bytes(mintCalldata), false);
        assertEq(proxy.implementation(), address(implementation));
    }


    function testNotUUPSUpgradeToAndCallUUPS() public {
        // mint calldata
        bytes memory mintCalldata = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(this),
            uint256(1),
            uint256(1),
            bytes("")
        );

        vm.expectRevert("new implementation is not UUPS");
        proxy.upgradeToAndCallUUPS(address(notUUPSProxiableUUID), bytes(mintCalldata), false);
    } 

    function testUpgradeToAndCallUUPS() public {
        // mint calldata
        bytes memory mintCalldata = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(this),
            uint256(1),
            uint256(1),
            bytes("")
        );

        proxy.upgradeToAndCallUUPS(address(proxiableUUID), bytes(mintCalldata), false);
        assertEq(proxy.implementation(), address(proxiableUUID));
    } 


    function testProxyPassthrough() public {
        // set implementation
        proxy.upgradeTo(address(implementation));

        // perform a call on the implementation
        bytes memory mintCalldata = abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)",
            address(this),
            uint256(1),
            uint256(1),
            bytes("")
        );

        (bool success, bytes memory returnData) = address(proxy).call(mintCalldata);

        assertEq(success, true);
    }

    function testProxyPassthroughBytes() public {
        MockReturner returner = new MockReturner();
        // set implementation
        proxy.upgradeTo(address(returner));

        // perform a call on the implementation
        bytes memory boomerangString = bytes(string("return this string"));
        bytes memory returnData = MockReturner(address(proxy)).returnBytes(boomerangString);

        assertEq(returnData,boomerangString);
    }

    function testProxyPassthroughUint(uint256 x) public {
        MockReturner returner = new MockReturner();
        // set implementation
        proxy.upgradeTo(address(returner));

        // perform a call on the implementation
        uint256 returnData = MockReturner(address(proxy)).returnUint(x);
        assertEq(returnData,x);
    }

    function testProxyPassthroughAddress(address add) public {
        MockReturner returner = new MockReturner();
        // set implementation
        proxy.upgradeTo(address(returner));

        // perform a call on the implementation
        address returnData = MockReturner(address(proxy)).returnAddress(add);
        assertEq(returnData,add);
    }
}