// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MerkleDistributorTest is Test {
    ERC20 token;
    bytes32 constant merkleRoot = bytes32(uint256(0x4a9dd8c7af51100e0f04f128c61c526a9380cfde11c830800f9e670429440c1f));

    // Test User 1
    address user1 = 0xD08c8e6d78a1f64B1796d6DC3137B19665cb6F1F;
    uint amount1 = 10;
    uint index1 = 0;

    // Test User 2
    address user2 = 0xb7D15753D3F76e7C892B63db6b4729f700C01298;
    uint amount2 = 15;
    uint index2 = 1;

    // Test User 3
    address user3 = 0xf69Ca530Cd4849e3d1329FBEC06787a96a3f9A68;
    uint amount3 = 20;
    uint index3 = 2;

    // Test User 4
    address user4 = 0xa8532aAa27E9f7c3a96d754674c99F1E2f824800;
    uint amount4 = 30;
    uint index4 = 3;

    /// @dev Address of the SimpleStore contract.
    MerkleDistributor public merkleDistributor;

    /// @dev Setup the testing environment.
    function setUp() public {
        // Deploy test erc20 token
        token = new TestToken(10_000 * 10**18);

        // Deploy MerkleDistributor
        string memory wrapper_code = vm.readFile("test/utils/mocks/MerkleDistributorWrappers.huff");
        merkleDistributor = MerkleDistributor(
            HuffDeployer
                .config()
                .with_code(wrapper_code)
                .with_args(bytes.concat(abi.encode(address(token)), abi.encode(merkleRoot)))
                .deploy("utils/MerkleDistributor")
        );

        // Transfer to merkledistributor
        uint currBalance = token.balanceOf(address(this));
        token.transfer(address(merkleDistributor), currBalance);

        // Confirm constructor variables set properly
        assertEq(merkleDistributor.getTokenAddress(), address(token));
        assertEq(merkleDistributor.getMerkleRoot(), merkleRoot);
    }

    /// @dev Ensure revert for claimed index
    function testRevert() public {
        bytes32[] memory proof4 = new bytes32[](2);
        proof4[0] = 0x39245471a38c683d6559bbc50b3c9ed8ec3b6d79c0e63c466e68a261bd4394fa;
        proof4[1] = 0x491dec713e1401118c9b1a82bb2fc861fe3500d34ee49e5ab56f514fded22de3;

        merkleDistributor.claim(index4, user4, amount4, proof4);
        assert(merkleDistributor.isClaimed(index4));
    }

    /// @dev Ensure tokens transfer
    function testClaimTransfer() public {
        bytes32[] memory proof3 = new bytes32[](2);
        proof3[0] = 0x85b9749ddb06ff3ff63b0a0333c8b19b29a7ffb4d9a6891c6f1351a2b670d5bb;
        proof3[1] = 0x97ca9eb557c807d4223d28a6b6e2581aaeb2cd26a7d24c4195db6dcbf3eafc45;

        uint balanceBeforeUser3 = token.balanceOf(user3);
        merkleDistributor.claim(index3, user3, amount3, proof3);
        uint balanceAfterUser3 = token.balanceOf(user3);

        assert(balanceBeforeUser3 + amount3 == balanceAfterUser3);
    }

    /// @dev Ensure claim mechanism works
    function testClaimOnce() public {
        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = 0x3fdbb9ff8c87c843885788bfb3023d1351a05efb9a5a4dfd5332081fe8be4c31;
        proof1[1] = 0x491dec713e1401118c9b1a82bb2fc861fe3500d34ee49e5ab56f514fded22de3;
        merkleDistributor.claim(index1, user1, amount1, proof1);
    }
}

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MDT", "Merk", 18) {
        _mint(msg.sender, initialSupply);
    }
}

interface MerkleDistributor {
    function getMerkleRoot() external view returns (bytes32);
    function getTokenAddress() external view returns (address);
    function isClaimed(uint256) external view returns (bool);
    function claim(uint256, address, uint256, bytes32[] calldata) external;
}