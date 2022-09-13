// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface IERC721 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function tokenURI(uint256) external returns (string memory);

    function mint(address, uint256) payable external;
    function burn(uint256) external;

    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function approve(address, uint256) external;
    function setApprovalForAll(address, bool) external;

    function getApproved(uint256) external returns (address);
    function isApprovedForAll(address, address) external returns (bool);
    function ownerOf(uint256) external returns (address);
    function balanceOf(address) external returns (uint256);
    function supportsInterface(bytes4) external returns (bool);
}

contract ERC721Test is Test {
    IERC721 token;

    function setUp() public {
        // Deploy the ERC721
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC721Wrapper.huff");
        token = IERC721(HuffDeployer.config().with_code(wrapper_code).deploy("tokens/ERC721"));
    }

    /// @notice Test the ERC721 Metadata
    function invariantMetadata() public {
        assertEq(keccak256(abi.encode(token.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(token.symbol())), keccak256(abi.encode("TKN")));
    }

    function testMint() public {
        vm.expectRevert(bytes("INVALID_RECIPIENT"));
        token.mint(address(0x0), 1337);

        // We can still mint the token
        token.mint(address(0xBEEF), 1337);

        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.ownerOf(1337), address(0xBEEF));

        // Minting the same token twice should fail
        vm.expectRevert(bytes("ALREADY_MINTED"));
        token.mint(address(0xBEEF), 1337);
    }

    function testBurn() public {
        // We can't burn a token we don't have
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0));
        vm.expectRevert(bytes("NOT_MINTED"));
        token.burn(1337);

        // Mint a token
        token.mint(address(this), 1337);
        assertEq(token.balanceOf(address(this)), 1);
        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(this));

        // Set approval and then check that it is zeroed out
        token.approve(address(0xBEEF), 1337);
        assertEq(token.getApproved(1337), address(0xBEEF));

        // Now we should be able to burn the minted token
        token.burn(1337);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0));

        vm.expectRevert(bytes("NOT_MINTED"));
        token.burn(1337);
    }

    function testApprove() public {
        token.mint(address(this), 1337);
        token.approve(address(0xBEEF), 1337);
        assertEq(token.getApproved(1337), address(0xBEEF));

        token.approve(address(0xCAFE), 1337);
        assertEq(token.getApproved(1337), address(0xCAFE));
    }

    function testApproveBurn() public {
        token.mint(address(this), 1337);
        token.approve(address(0xBEEF), 1337);
        token.burn(1337);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(1337), address(0));
    }

    function testApproveAll() public {
        assertFalse(token.isApprovedForAll(address(this), address(0xBEEF)));
        token.setApprovalForAll(address(0xBEEF), true);
        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
        token.setApprovalForAll(address(0xBEEF), false);
        assertFalse(token.isApprovedForAll(address(this), address(0xBEEF)));
    }
}
