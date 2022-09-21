// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

import { MockAuthChild } from "solmate/test/utils/mocks/MockAuthChild.sol";
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
    MockAuthChild implementation;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/Create3Wrappers.huff");
        clones = Clones(HuffDeployer.deploy_with_code("utils/CREATE3", wrapper_code));

        // Deploy a mock contract to use as the implementation
        implementation = new MockAuthChild();
    }

    // function testClone() public {
    //     MockAuthChild deployed = MockAuthChild(clones.clone(type(MockAuthChild).creationCode));
    //     assertEq(address(deployed), clones.predictDeterministicAddress(type(MockAuthChild).creationCode, bytes32(0)));
    // }

    function testPredictDeterministicAddress() public {
        bytes32 salt = keccak256(bytes("A salt!"));
        assertEq(
            clones.predictDeterministicAddress(address(implementation), salt),
            keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(type(MockAuthChild).creationCode))
            )).fromLast20Bytes()
        );
    }
}