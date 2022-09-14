// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

interface IERC721 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function tokenURI(uint256) external returns (string memory);

    function mint(address, uint256) payable external;
    function burn(uint256) external;

    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;

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
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC721Wrappers.huff");
        token = IERC721(HuffDeployer.config().with_code(wrapper_code).deploy("tokens/ERC721"));
    }

    /// @notice Test the ERC721 Metadata
    function testMetadata() public {
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

    /// @notice Tests Transfer From
    /// @notice sbf is coming to steal your tokens
    function testTransferFrom(address sbf) public {
        address from = address(0xABCD);
        vm.assume(sbf != from);
        vm.assume(sbf != address(0));

        // Mint the from a token
        token.mint(from, 1337);


        // Non owner cannot transfer
        vm.expectRevert(bytes("WRONG_FROM"));
        token.transferFrom(sbf, address(this), 1337);

        // sbf can't steal our tokens
        vm.startPrank(sbf);
        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        token.transferFrom(from, sbf, 1337);
        vm.stopPrank();

        // Prank from
        vm.startPrank(from);

        // Cannot transfer to 0
        vm.expectRevert(bytes("INVALID_RECIPIENT"));
        token.transferFrom(from, address(0), 1337);

        // The owner can transfer it!
        token.transferFrom(from, address(0xBEEF), 1337);
        vm.stopPrank();

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    /// @notice Tests Transferring from yourself
    function testTransferFromSelf(address minter) public {
        vm.assume(minter != address(0));

        // Mint a token
        token.mint(minter, 1337);

        // Transfer from self
        vm.prank(minter);
        token.transferFrom(minter, address(0xBEEF), 1337);

        // Check that it worked
        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(address from) public {
        vm.assume(from != address(0));

        // Mint a token
        token.mint(from, 1337);

        // Give this contract approval to transfer
        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        // The approved address can transfer
        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(address from) public {
        vm.assume(from != address(0));
        vm.assume(from != address(0xBEEF));

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(address from) public {
        vm.assume(from != address(0));

        ERC721Recipient recipient = new ERC721Recipient();
        console2.logBytes4(ERC721Recipient.onERC721Received.selector);

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(keccak256(abi.encode(recipient.data())), keccak256(abi.encode("")));
    }
}
