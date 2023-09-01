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

    event Received(address operator, address from, uint256 id, bytes data);

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        emit Received(_operator, _from, _id, _data);
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}


interface IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256) external returns (string memory);

    function mint(address, uint256) payable external;
    function burn(uint256) external;

    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256, bytes calldata) external;

    function approve(address, uint256) external;
    function setApprovalForAll(address, bool) external;

    function getApproved(uint256) external returns (address);
    function isApprovedForAll(address, address) external view returns (bool);
    function ownerOf(uint256) external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function supportsInterface(bytes4) external view returns (bool);
}

interface SafeMintableERC721 is IERC721 {
    function safeMint(address to, uint256 tokenId, bytes memory data) external;
    function safeMint(address to, uint256 tokenId) external;
}

contract ERC721Test is Test {
    SafeMintableERC721 token;

    function setUp() public {
        // Deploy the ERC721
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC721Wrappers.huff");
        token = SafeMintableERC721(HuffDeployer.config().with_code(wrapper_code).with_args(bytes.concat(abi.encode("Token"), abi.encode("TKN"))).deploy("tokens/ERC721"));
    }

    /// @notice Test the ERC721 Metadata
    function testMetadata() public {
        assertEq(keccak256(abi.encode(token.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(token.symbol())), keccak256(abi.encode("TKN")));
        assertEq(keccak256(abi.encode(token.tokenURI(1))), keccak256(abi.encode("")));
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
        
        vm.expectRevert(bytes("NOT_MINTED"));
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
        
        vm.expectRevert(bytes("NOT_MINTED"));
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
        vm.assume(from != address(0xBEEF));

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
        vm.assume(from != address(recipient));

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

    function testSafeTransferFromToERC721RecipientWithData(address from) public {
        vm.assume(from != address(0));

        ERC721Recipient recipient = new ERC721Recipient();
        vm.assume(from != address(recipient));

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(keccak256(abi.encode(recipient.data())), keccak256(abi.encode("testing 123")));
    }



    function testSafeMintToEOA() public {
        token.safeMint(address(0xBEEF), 1337);

        assertEq(token.ownerOf(1337), address(address(0xBEEF)));
        assertEq(token.balanceOf(address(address(0xBEEF))), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337);

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(keccak256(abi.encode(to.data())), keccak256(abi.encode("")));
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337, "testing 123");

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(keccak256(abi.encode(to.data())), keccak256(abi.encode("testing 123")));
    }

    function testFailMintToZero() public {
        token.mint(address(0), 1337);
    }

    function testFailDoubleMint() public {
        token.mint(address(0xBEEF), 1337);
        token.mint(address(0xBEEF), 1337);
    }

    function testFailBurnUnMinted() public {
        token.burn(1337);
    }

    function testFailDoubleBurn() public {
        token.mint(address(0xBEEF), 1337);

        token.burn(1337);
        token.burn(1337);
    }

    function testFailApproveUnMinted() public {
        token.approve(address(0xBEEF), 1337);
    }

    function testFailApproveUnAuthorized() public {
        token.mint(address(0xCAFE), 1337);

        token.approve(address(0xBEEF), 1337);
    }

    function testFailTransferFromUnOwned() public {
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromWrongFrom() public {
        token.mint(address(0xCAFE), 1337);

        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromToZero() public {
        token.mint(address(this), 1337);

        token.transferFrom(address(this), address(0), 1337);
    }

    function testFailTransferFromNotOwner() public {
        token.mint(address(0xFEED), 1337);

        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        token.mint(address(this), 1337);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToNonERC721Recipient() public {
        token.safeMint(address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeMintToNonERC721RecipientWithData() public {
        token.safeMint(address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToRevertingERC721Recipient() public {
        token.safeMint(address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData() public {
        token.safeMint(address(new RevertingERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
        token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
        token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert(bytes("ZERO_ADDRESS"));
        uint256 bal = token.balanceOf(address(0));
    }

    // function testFailOwnerOfUnminted() public view {
    //     token.ownerOf(1337);
    // }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        assertEq(token.balanceOf(to), 1);
        assertEq(token.ownerOf(id), to);
    }

    function testBurn(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        token.burn(id);

        assertEq(token.balanceOf(to), 0);

        vm.expectRevert(bytes("NOT_MINTED"));
        token.ownerOf(id);
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(address(this), id);

        token.approve(to, id);

        assertEq(token.getApproved(id), to);
    }

    function testApproveBurn(address to, uint256 id) public {
        token.mint(address(this), id);

        token.approve(address(to), id);

        token.burn(id);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(id), address(0));

        vm.expectRevert(bytes("NOT_MINTED"));
        address owner = token.ownerOf(id);
        assertEq(owner, address(0));
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        vm.prank(from);
        token.approve(address(this), id);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        token.mint(address(this), id);

        token.transferFrom(address(this), to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(keccak256(abi.encode(recipient.data())), keccak256(abi.encode("")));
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id, data);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(keccak256(abi.encode(recipient.data())), keccak256(abi.encode(data)));
    }

    function testSafeMintToEOA(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.safeMint(to, id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(keccak256(abi.encode(to.data())), keccak256(abi.encode("")));
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id, data);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(keccak256(abi.encode(to.data())), keccak256(abi.encode(data)));
    }

    function testFailMintToZero(uint256 id) public {
        token.mint(address(0), id);
    }

    function testFailDoubleMint(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        token.mint(to, id);
    }

    function testFailBurnUnMinted(uint256 id) public {
        token.burn(id);
    }

    function testFailDoubleBurn(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        token.burn(id);
        token.burn(id);
    }

    function testFailApproveUnMinted(uint256 id, address to) public {
        token.approve(to, id);
    }

    function testFailApproveUnAuthorized(
        address owner,
        uint256 id,
        address to
    ) public {
        if (owner == address(0) || owner == address(this)) owner = address(0xBEEF);

        token.mint(owner, id);

        token.approve(to, id);
    }

    function testFailTransferFromUnOwned(
        address from,
        address to,
        uint256 id
    ) public {
        token.transferFrom(from, to, id);
    }

    function testFailTransferFromWrongFrom(
        address owner,
        address from,
        address to,
        uint256 id
    ) public {
        if (owner == address(0)) to = address(0xBEEF);
        if (from == owner) revert();

        token.mint(owner, id);

        token.transferFrom(from, to, id);
    }

    function testFailTransferFromToZero(uint256 id) public {
        token.mint(address(this), id);

        token.transferFrom(address(this), address(0), id);
    }

    function testFailTransferFromNotOwner(
        address from,
        address to,
        uint256 id
    ) public {
        if (from == address(this)) from = address(0xBEEF);

        token.mint(from, id);

        token.transferFrom(from, to, id);
    }

    function testFailSafeTransferFromToNonERC721Recipient(uint256 id) public {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToRevertingERC721Recipient(uint256 id) public {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data)
        public
    {
        token.mint(address(this), id);

        token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testFailSafeMintToNonERC721Recipient(uint256 id) public {
        token.safeMint(address(new NonERC721Recipient()), id);
    }

    function testFailSafeMintToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.safeMint(address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeMintToRevertingERC721Recipient(uint256 id) public {
        token.safeMint(address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        token.safeMint(address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
        token.safeMint(address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data) public {
        token.safeMint(address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testOwnerOfUnminted(uint256 id) public {
        vm.expectRevert(bytes("NOT_MINTED"));
        address owner = token.ownerOf(id);
    }
}
