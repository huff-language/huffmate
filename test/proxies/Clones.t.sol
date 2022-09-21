// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import { MockAuthChild } from "solmate/test/utils/mocks/MockAuthChild.sol";
import { Bytes32AddressLib } from "solmate/utils/Bytes32AddressLib.sol";

interface Clones {
    function clone(address implementation) external returns (address instance);
    function cloneDeterministic(address implementation, bytes32 salt) external returns (address instance);
    function predictDeterministicAddress(address implementation, bytes32 salt) external returns (address predicted);
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) external returns (address predicted);
}

contract ClonesTest is Test {
    using Bytes32AddressLib for bytes32;

    Clones clones;
    MockAuthChild implementation;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/proxies/mocks/ClonesWrappers.huff");
        clones = Clones(HuffDeployer.deploy_with_code("proxies/Clones", wrapper_code));

        // Deploy a mock contract to use as the implementation
        implementation = new MockAuthChild();
    }

    // function testClone() public {
    //     MockAuthChild deployed = MockAuthChild(clones.clone(type(MockAuthChild).creationCode));
    //     assertEq(address(deployed), clones.predictDeterministicAddress(type(MockAuthChild).creationCode, bytes32(0)));
    // }

    function testClonesPredictDeterministicAddress() public {
        bytes32 salt = keccak256(bytes("A salt!"));

        // Build creation code
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            address(implementation),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        console2.log("Creation code:");
        console2.logBytes(creationCode);

        bytes32 creationCodeHash = keccak256(creationCode);
        console2.log("Creation code hash:");
        console2.logBytes32(creationCodeHash);

        bytes memory packed = abi.encodePacked(bytes1(0xff), address(clones), salt, creationCodeHash);
        console2.log("Packed:");
        console2.logBytes(packed);

        // Constructed the expected address
        address expected = keccak256(packed).fromLast20Bytes();
        console2.log("Expected address:");
        console2.log(expected);

        // Validate expected address
        assertEq(
            clones.predictDeterministicAddress(address(implementation), salt),
            expected
        );
    }
}