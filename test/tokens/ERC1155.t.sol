// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

// Tests modified from https://github.com/transmissions11/solmate/blob/main/src/test/ERC1155.t.sol
contract ERC1155Test is Test {
    /// @dev Address of the SimpleStore contract.  
    ERC1155 public erc1155;
    ERC1155Recipient public erc1155Recipient;

    /// @dev Setup the testing environment.
    function setUp() public {
        erc1155 = ERC1155(HuffDeployer.deploy("tokens/ERC1155"));
        erc1155Recipient = new ERC1155Recipient();
    }

    /// @dev Ensure that you can set and get the value.
    // TODO: fuzzing on these
    function testMint1155() public {
        uint256 tokenId = 1;
        uint256 amount = 1;
        address eoa = address(0xbeef);

        erc1155.mint(eoa, tokenId, amount, "");
        console.log(erc1155.balanceOf(eoa, tokenId));
        assertEq(erc1155.balanceOf(eoa, tokenId), amount);
        // TODO: mint to a contract recipient with data
    }

    function testMint1155Recipient() public {
        uint256 tokenId = 1;
        uint256 amount = 1;
        // mint to a contract recipient
        erc1155.mint(address(erc1155Recipient), tokenId, amount,  hex'00');
        assertEq(erc1155.balanceOf(address(erc1155Recipient), tokenId), amount);
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
        erc1155.safeTransferFrom(from, to, 1, 1, hex'00');

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

    function safeTransferToContractFromApproved() public {
        address from = address(0xbeef);
        address to = address(erc1155Recipient);
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

    function testBatchMint() public {
        address to = address(0xBeef);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        erc1155.batchMint(to, ids, amounts, hex'00');

        assertEq(1, erc1155.balanceOf(to, 1));
        assertEq(1, erc1155.balanceOf(to, 2));
    }

    function testBatchMintContract() public {
        address to = address(erc1155Recipient);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        erc1155.batchMint(to, ids, amounts, hex'00');

        assertEq(1, erc1155.balanceOf(to, 1));
        assertEq(1, erc1155.balanceOf(to, 2));
    }

    function testBurn() public {
        address from = address(0xbeef);
        uint256 tokenId = 1;
        uint256 amount = 1;

        erc1155.mint(from, tokenId, amount, "");
        assertEq(amount, erc1155.balanceOf(from, tokenId));

        erc1155.burn(from, tokenId, amount);
        assertEq(0, erc1155.balanceOf(from, tokenId));
    }

    function testBatchBurn() public {
        // mint the tokens
        address to = address(0xBeef);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        erc1155.batchMint(to, ids, amounts, hex'00');
        assertEq(1, erc1155.balanceOf(to, 1));
        assertEq(1, erc1155.balanceOf(to, 2));

        // burn the same tokens
        erc1155.batchBurn(to, ids, amounts);
        assertEq(0, erc1155.balanceOf(to, 1));
        assertEq(0, erc1155.balanceOf(to, 2));
    }

    function testSafeBatchTransferFrom1155() public {
                // mint the tokens
        address from = address(0xabcd);
        address to = address(0xBeef);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;


        erc1155.batchMint(from, ids, amounts, hex'00');
        assertEq(1, erc1155.balanceOf(from, 1));
        assertEq(1, erc1155.balanceOf(from, 2));

        // transfer the tokens
        erc1155.safeBatchTransferFrom(from, to, ids, amounts, hex'00');
        assertEq(0, erc1155.balanceOf(from, 1));
        assertEq(0, erc1155.balanceOf(from, 2));
        assertEq(1, erc1155.balanceOf(to, 1));
        assertEq(1, erc1155.balanceOf(to, 2));
    }

    function testSafeBatchTransferFrom1155Receiver() public {
                // mint the tokens
        address from = address(0xabcd);
        address to = address(erc1155Recipient);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;


        erc1155.batchMint(from, ids, amounts, hex'00');
        // assertEq(1, erc1155.balanceOf(from, 1));
        // assertEq(1, erc1155.balanceOf(from, 2));

        // transfer the tokens
        erc1155.safeBatchTransferFrom(from, to, ids, amounts, hex'00');
        assertEq(0, erc1155.balanceOf(from, 1));
        assertEq(0, erc1155.balanceOf(from, 2));
        assertEq(1, erc1155.balanceOf(to, 1));
        assertEq(1, erc1155.balanceOf(to, 2));
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
    function batchMint(address,uint256[] memory, uint256[] memory, bytes memory) external;
    function setApprovalForAll(address,bool) external;
    function safeTransferFrom(address,address,uint256,uint256,bytes calldata) external;
    function safeBatchTransferFrom(address,address,uint256[] memory, uint256[] memory, bytes memory) external;
    function burn(address,uint256,uint256) external;
    function batchBurn(address,uint256[] memory, uint256[] memory) external;
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}


contract ERC1155Recipient is ERC1155TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        amount = _amount;
        mintData = _data;

        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    address public batchOperator;
    address public batchFrom;
    uint256[] internal _batchIds;
    uint256[] internal _batchAmounts;
    bytes public batchData;

    function batchIds() external view returns (uint256[] memory) {
        return _batchIds;
    }

    function batchAmounts() external view returns (uint256[] memory) {
        return _batchAmounts;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external override returns (bytes4) {
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract RevertingERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector)));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector)));
    }
}

contract WrongReturnDataERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0xCAFEBEEF;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC1155Recipient {}


