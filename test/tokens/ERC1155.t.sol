// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract ERC1155Test is Test {
    /// @dev Address of the SimpleStore contract.  
    ERC1155 public erc1155;

    /// @dev Setup the testing environment.
    function setUp() public {
        erc1155 = ERC1155(HuffDeployer.deploy("tokens/ERC1155"));
    }

    /// @dev Ensure that you can set and get the value.
    // TODO: fuzzing on these
    function testMint() public {
        uint256 tokenId = 1;
        uint256 amount = 1;
        address eoa = address(0xbeef);

        erc1155.mint(eoa, tokenId, amount, "");
        console.log(erc1155.balanceOf(eoa, tokenId));
        assertEq(erc1155.balanceOf(eoa, tokenId), amount);
    }

    function testMintMultiple() public {
        uint256 tokenId = 1;
        uint256 amount = 10;
        address eoa = address(0xbeef);

        erc1155.mint(eoa, tokenId, amount, "");
        assertEq(amount, erc1155.balanceOf(eoa, tokenId));

        erc1155.mint(eoa, tokenId, amount, "");
        assertEq(amount * 2, erc1155.balanceOf(eoa, tokenId));
    }

    function testName() public {
        // returns the contracts name as "HUFFERC1155"
        console.log(erc1155.name());
        assertEq("HUFFERC1155", erc1155.name());
    }

    function testSymbol() public {
        // returns the contracts symbol as "H1155"
        console.log(erc1155.symbol());
        assertEq("H1155", erc1155.symbol());
    }

    function testIsApprovedForAll(address owner, address operator) public {
        // returns false owner is yet to approve tokens
        console.log(erc1155.isApprovedForAll(owner, operator));
        assertEq(false, erc1155.isApprovedForAll(owner, operator));
    
        // owner approves operator to transfer tokens
        vm.prank(owner);
        erc1155.setApprovalForAll(operator, true);

        // returns true owner is now approved to transfer tokens
        console.log(erc1155.isApprovedForAll(owner, operator));
        assertEq(true, erc1155.isApprovedForAll(owner, operator));

        // set back to false
        vm.prank(owner);
        erc1155.setApprovalForAll(operator, false);

        // // returns false owner is no longer approved to transfer tokens
        console.log(erc1155.isApprovedForAll(owner, operator));
        assertEq(false, erc1155.isApprovedForAll(owner, operator));
    }

    function testSafeTransferFromOwner() public {
        address from = address(0xbeef);
        address to = address(0xdead);

        erc1155.mint(from, 1, 1, "");
        assertEq(1, erc1155.balanceOf(from, 1));

        // show allow as coming from sender
        vm.prank(from);
        erc1155.safeTransferFrom(from, to, 1, 1, "");

        assertEq(0, erc1155.balanceOf(from, 1));
        assertEq(1, erc1155.balanceOf(to, 1));
    }

    function testSafeTransferFromApproved() public {
        address from = address(0xbeef);
        address to = address(0xdead);
        address approved = address(0xaaaa);

        erc1155.mint(from, 1, 1, "");
        assertEq(1, erc1155.balanceOf(from, 1));

        // show allow as coming from sender
        vm.prank(from);
        erc1155.setApprovalForAll(approved, true);

        // show allow as coming from approved
        vm.prank(approved);
        erc1155.safeTransferFrom(from, to, 1, 1, "");

        assertEq(0, erc1155.balanceOf(from, 1));
        assertEq(1, erc1155.balanceOf(to, 1));
    }
    
}

interface ERC1155 {
    // view
    function balanceOf(address,uint256) view external returns(uint256);
    function name() view external returns(string memory);
    function symbol() view external returns(string memory);
    function isApprovedForAll(address,address) view external returns(bool);

    // stateful 
    function mint(address,uint256,uint256,bytes calldata) external;
    function setApprovalForAll(address,bool) external;
    function safeTransferFrom(address,address,uint256,uint256,bytes calldata) external;

}
