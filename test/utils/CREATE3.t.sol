// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;


import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

// import {WETH} from "../tokens/WETH.sol";
// import {DSTestPlus} from "./utils/DSTestPlus.sol";
// import {MockERC20} from "./utils/mocks/MockERC20.sol";
// import {MockAuthChild} from "./utils/mocks/MockAuthChild.sol";

interface CREATE3 {
    function deploy(bytes32 salt, bytes memory creationCode, uint256 value) external returns (address deployed);
}

contract CREATE3Test is Test {
    CREATE3 create3;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/Create3Wrappers.huff");
        create3 = CREATE3(HuffDeployer.deploy_with_code("utils/CREATE3", wrapper_code));
    }

    // function testDeployERC20() public {
    //     bytes32 salt = keccak256(bytes("A salt!"));



    //     MockERC20 deployed = MockERC20(
    //         create3.deploy(
    //             salt,
    //             abi.encodePacked(type(MockERC20).creationCode, abi.encode("Mock Token", "MOCK", 18)),
    //             0
    //         )
    //     );

    //     assertEq(address(deployed), create3.getDeployed(salt));

    //     assertEq(deployed.name(), "Mock Token");
    //     assertEq(deployed.symbol(), "MOCK");
    //     assertEq(deployed.decimals(), 18);
    // }

    // function testFailDoubleDeploySameBytecode() public {
    //     bytes32 salt = keccak256(bytes("Salty..."));

    //     // create3.deploy(salt, type(MockAuthChild).creationCode, 0);
    //     // create3.deploy(salt, type(MockAuthChild).creationCode, 0);
    // }

    // function testFailDoubleDeployDifferentBytecode() public {
    //     bytes32 salt = keccak256(bytes("and sweet!"));

    //     // create3.deploy(salt, type(WETH).creationCode, 0);
    //     // create3.deploy(salt, type(MockAuthChild).creationCode, 0);
    // }

    // function testDeployERC20(
    //     bytes32 salt,
    //     string calldata name,
    //     string calldata symbol,
    //     uint8 decimals
    // ) public {
    //     MockERC20 deployed = MockERC20(
    //         create3.deploy(salt, abi.encodePacked(type(MockERC20).creationCode, abi.encode(name, symbol, decimals)), 0)
    //     );

    //     assertEq(address(deployed), create3.getDeployed(salt));

    //     assertEq(deployed.name(), name);
    //     assertEq(deployed.symbol(), symbol);
    //     assertEq(deployed.decimals(), decimals);
    // }

    function testFailDoubleDeploySameBytecode(bytes32 salt, bytes calldata bytecode) public {
        create3.deploy(salt, bytecode, 0);
        create3.deploy(salt, bytecode, 0);
    }

    function testFailDoubleDeployDifferentBytecode(
        bytes32 salt,
        bytes calldata bytecode1,
        bytes calldata bytecode2
    ) public {
        create3.deploy(salt, bytecode1, 0);
        create3.deploy(salt, bytecode2, 0);
    }
}
