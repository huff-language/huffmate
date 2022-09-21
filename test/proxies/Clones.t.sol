// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import { MockERC1155 } from "solmate/test/utils/mocks/MockERC1155.sol";
import { Bytes32AddressLib } from "solmate/utils/Bytes32AddressLib.sol";

interface Clones {
    function clone(address implementation) external returns (address instance);
    function cloneDeterministic(address implementation, bytes32 salt) external returns (address instance);
    function predictDeterministicAddress(address implementation, bytes32 salt) external view returns (address predicted);
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) external pure returns (address predicted);
}

contract ClonesTest is Test {
    using Bytes32AddressLib for bytes32;

    Clones clones;
    MockERC1155 implementation;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/proxies/mocks/ClonesWrappers.huff");
        clones = Clones(HuffDeployer.deploy_with_code("proxies/Clones", wrapper_code));

        // Deploy a mock contract to use as the implementation
        implementation = new MockERC1155();
    }

    function testClone() public {
        address instance = clones.clone(address(implementation));
        assertTrue(instance != address(0));
    }

    function testCloneDeterministic() public {
        bytes32 salt = keccak256(bytes("A salt!"));
        address instance = clones.cloneDeterministic(address(implementation), salt);
        address predicted = clones.predictDeterministicAddress(address(implementation), salt);
        assertEq(instance, predicted);
    }

    function testClonesPredictDeterministicAddress() public {
        bytes32 salt = keccak256(bytes("A salt!"));

        // Build creation code
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            address(implementation),
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        bytes32 creationCodeHash = keccak256(creationCode);

        bytes memory packed = abi.encodePacked(bytes1(0xff), address(clones), salt, creationCodeHash);

        // Constructed the expected address
        address expected = keccak256(packed).fromLast20Bytes();

        // Validate expected address
        assertEq(
            clones.predictDeterministicAddress(address(implementation), salt),
            expected
        );
        assertEq(
            clones.predictDeterministicAddress(address(implementation), salt, address(clones)),
            expected
        );
    }
}