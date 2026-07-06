// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../test-utils/FuzzingUtils.sol";


interface ERC1155 {
    // view
    function balanceOf(address,uint256) view external returns(uint256);
    function balanceOfBatch(address[] calldata, uint256[] calldata) view external returns(uint256[] memory);
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

// Tests modified from https://github.com/transmissions11/solmate/blob/main/src/test/ERC1155.t.sol
contract ERC1155Test is Test, ERC1155Recipient, FuzzingUtils {
    /// @dev Address of the SimpleStore contract.
    ERC1155 public token;

    // for fuzzing
    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    /// @dev Setup the testing environment.
    function setUp() public {
        string memory wrappers = vm.readFile("test/tokens/mocks/ERC1155Wrappers.huff");
        token = ERC1155(
            HuffDeployer.config()
                .with_args(bytes.concat(abi.encode("Token"), abi.encode("TKN")))
                .with_code(wrappers)
                .deploy("tokens/ERC1155")
        );
    }

    function testMetadataConstant() public {
        assertEq(keccak256(abi.encode(token.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(token.symbol())), keccak256(abi.encode("TKN")));
    }

    function testMintToEOA() public {
        uint256 tokenId = 1;
        uint256 amount = 1;
        address eoa = address(0xbeef);

        token.mint(eoa, tokenId, amount, "");
        assertEq(token.balanceOf(eoa, tokenId), amount);
    }

    function testMint1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();
        token.mint(address(to), 1337, 1, "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");
    }

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(0xBEEF), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 300);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 400);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 500);
    }


    function testBatchMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(to), ids, amounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), amounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 100);
        assertEq(token.balanceOf(address(to), 1338), 200);
        assertEq(token.balanceOf(address(to), 1339), 300);
        assertEq(token.balanceOf(address(to), 1340), 400);
        assertEq(token.balanceOf(address(to), 1341), 500);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1337, 100, "");

        token.burn(address(0xBEEF), 1337, 70);

        assertEq(token.balanceOf(address(0xBEEF), 1337), 30);
    }

    function testBatchBurn() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 50;
        burnAmounts[1] = 100;
        burnAmounts[2] = 150;
        burnAmounts[3] = 200;
        burnAmounts[4] = 250;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        token.batchBurn(address(0xBEEF), ids, burnAmounts);

        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);
        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(to), 1337, 70, "testing 123");

        assertEq(to.operator(), address(this));
        assertEq(to.from(), from);
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromSelf() public {
        token.mint(address(this), 1337, 100, "");

        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(address(this), 1337), 30);
    }


    function testSafeBatchTransferFromToEOAs
    () public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(to), ids, transferAmounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), from);
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), transferAmounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(to), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(to), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(to), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(to), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(to), 1341), 250);
    }

    function testBatchBalanceOf() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(tos, ids);

        console.log(balances[0]);
        console.log(balances[1]);
        console.log(balances[2]);
        console.log(balances[3]);
        console.log(balances[4]);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function test_RevertWhen_MintToZero() public {
        vm.expectRevert();
        token.mint(address(0), 1337, 1, "");
    }

    function test_RevertWhen_MintToNonERC155Recipient() public {
        address to = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.mint(to, 1337, 1, "");
    }

    function test_RevertWhen_MintToRevertingERC155Recipient() public {
        address to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.mint(to, 1337, 1, "");
    }

    function test_RevertWhen_MintToWrongReturnDataERC155Recipient() public {
        address to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.mint(to, 1337, 1, "");
    }

    function test_RevertWhen_BurnInsufficientBalance() public {
        token.mint(address(0xBEEF), 1337, 70, "");
        vm.expectRevert();
        token.burn(address(0xBEEF), 1337, 100);
    }

    function test_RevertWhen_SafeTransferFromInsufficientBalance() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 70, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeTransferFrom(from, address(0xBEEF), 1337, 100, "");
    }

    function test_RevertWhen_SafeTransferFromSelfInsufficientBalance() public {
        token.mint(address(this), 1337, 70, "");
        vm.expectRevert();
        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 100, "");
    }

    function test_RevertWhen_SafeTransferFromToZero() public {
        token.mint(address(this), 1337, 100, "");
        vm.expectRevert();
        token.safeTransferFrom(address(this), address(0), 1337, 70, "");
    }

    function test_RevertWhen_SafeTransferFromToNonERC155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        address to = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(address(this), to, 1337, 70, "");
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC1155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        address to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(address(this), to, 1337, 70, "");
    }

    function test_RevertWhen_SafeTransferFromToWrongReturnDataERC1155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        address to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(address(this), to, 1337, 70, "");
    }

    function test_RevertWhen_SafeBatchTransferInsufficientBalance() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);

        mintAmounts[0] = 50;
        mintAmounts[1] = 100;
        mintAmounts[2] = 150;
        mintAmounts[3] = 200;
        mintAmounts[4] = 250;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 100;
        transferAmounts[1] = 200;
        transferAmounts[2] = 300;
        transferAmounts[3] = 400;
        transferAmounts[4] = 500;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function test_RevertWhen_SafeBatchTransferFromToZero() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeBatchTransferFrom(from, address(0), ids, transferAmounts, "");
    }

    function test_RevertWhen_SafeBatchTransferFromToNonERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(from, _to, ids, transferAmounts, "");
    }

    function test_RevertWhen_SafeBatchTransferFromToRevertingERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(from, _to, ids, transferAmounts, "");
    }


    function test_RevertWhen_SafeBatchTransferFromToWrongReturnDataERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(from, _to, ids, transferAmounts, "");
    }

    function test_RevertWhen_SafeBatchTransferFromWithArrayLengthMismatch() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](4);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function test_RevertWhen_BatchMintToZero() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        vm.expectRevert();
        token.batchMint(address(0), ids, mintAmounts, "");
    }

    function test_RevertWhen_BatchMintToNonERC1155Recipient() public {
        NonERC1155Recipient to = new NonERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        vm.expectRevert();
        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function test_RevertWhen_BatchMintToRevertingERC1155Recipient() public {
        RevertingERC1155Recipient to = new RevertingERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        vm.expectRevert();
        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function test_RevertWhen_BatchMintToWrongReturnDataERC1155Recipient() public {
        WrongReturnDataERC1155Recipient to = new WrongReturnDataERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        vm.expectRevert();
        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function test_RevertWhen_BatchMintWithArrayMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;

        vm.expectRevert();
        token.batchMint(address(0xBEEF), ids, amounts, "");
    }

    function test_RevertWhen_BatchBurnInsufficientBalance() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 50;
        mintAmounts[1] = 100;
        mintAmounts[2] = 150;
        mintAmounts[3] = 200;
        mintAmounts[4] = 250;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 100;
        burnAmounts[1] = 200;
        burnAmounts[2] = 300;
        burnAmounts[3] = 400;
        burnAmounts[4] = 500;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        vm.expectRevert();
        token.batchBurn(address(0xBEEF), ids, burnAmounts);
    }

    function test_RevertWhen_BatchBurnWithArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](4);
        burnAmounts[0] = 50;
        burnAmounts[1] = 100;
        burnAmounts[2] = 150;
        burnAmounts[3] = 200;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        vm.expectRevert();
        token.batchBurn(address(0xBEEF), ids, burnAmounts);
    }

    function test_RevertWhen_BalanceOfBatchWithArrayMismatch() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        vm.expectRevert();
        token.balanceOfBatch(tos, ids);
    }

    function testBatchMintToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[to][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[to][id] += mintAmount;
        }

        token.batchMint(to, normalizedIds, normalizedAmounts, mintData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(to, id), userMintAmounts[to][id]);
        }
    }

    function testBatchMintToERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        ERC1155Recipient to = new ERC1155Recipient();

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        token.batchMint(address(to), normalizedIds, normalizedAmounts, mintData);

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        assertEq(to.batchIds(), normalizedIds);
        assertEq(to.batchAmounts(), normalizedAmounts);
        assertEq(to.batchData(), mintData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(address(to), id), userMintAmounts[address(to)][id]);
        }
    }

    function testBurn(
        address to,
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 burnAmount
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        burnAmount = bound(burnAmount, 0, mintAmount);

        token.mint(to, id, mintAmount, mintData);

        token.burn(to, id, burnAmount);

        assertEq(token.balanceOf(address(to), id), mintAmount - burnAmount);
    }

    function testBatchBurn(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory burnAmounts,
        bytes memory mintData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        uint256 minLength = min3(ids.length, mintAmounts.length, burnAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedBurnAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = bound(mintAmounts[i], 0, remainingMintAmountForId);
            normalizedBurnAmounts[i] = bound(burnAmounts[i], 0, normalizedMintAmounts[i]);

            userMintAmounts[address(to)][id] += normalizedMintAmounts[i];
            userTransferOrBurnAmounts[address(to)][id] += normalizedBurnAmounts[i];
        }

        token.batchMint(to, normalizedIds, normalizedMintAmounts, mintData);

        token.batchBurn(to, normalizedIds, normalizedBurnAmounts);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(to, id), userMintAmounts[to][id] - userTransferOrBurnAmounts[to][id]);
        }
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testSafeTransferFromToEOA(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);
        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id, transferAmount, transferData);

        assertEq(token.balanceOf(to, id), transferAmount);
        assertEq(token.balanceOf(from, id), mintAmount - transferAmount);
    }

    function testSafeTransferFromToERC1155Recipient(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        bytes memory transferData
    ) public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(to), id, transferAmount, transferData);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), from);
        assertEq(to.id(), id);
        assertEq(to.mintData(), transferData);

        assertEq(token.balanceOf(address(to), id), transferAmount);
        assertEq(token.balanceOf(from, id), mintAmount - transferAmount);
    }

    function testSafeTransferFromSelf(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 transferAmount,
        address to,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);

        token.safeTransferFrom(address(this), to, id, transferAmount, transferData);

        assertEq(token.balanceOf(to, id), transferAmount);
        assertEq(token.balanceOf(address(this), id), mintAmount - transferAmount);
    }

    function testSafeBatchTransferFromToEOAFuzz(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        address from = address(0xABCD);

        // Skip self-transfers: the per-id balance bookkeeping below assumes `to`
        // and `from` are distinct (a self-transfer leaves `from`'s balance whole).
        if (to == from) return;

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
            userTransferOrBurnAmounts[from][id] += transferAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, to, normalizedIds, normalizedTransferAmounts, transferData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];

            assertEq(token.balanceOf(address(to), id), userTransferOrBurnAmounts[from][id]);
            assertEq(token.balanceOf(from, id), userMintAmounts[from][id] - userTransferOrBurnAmounts[from][id]);
        }
    }

    function testSafeBatchTransferFromToERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
            userTransferOrBurnAmounts[from][id] += transferAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(to), normalizedIds, normalizedTransferAmounts, transferData);

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), from);
        assertEq(to.batchIds(), normalizedIds);
        assertEq(to.batchAmounts(), normalizedTransferAmounts);
        assertEq(to.batchData(), transferData);

        for (uint256 i = 0; i < normalizedIds.length; i++) {
            uint256 id = normalizedIds[i];
            uint256 transferAmount = userTransferOrBurnAmounts[from][id];

            assertEq(token.balanceOf(address(to), id), transferAmount);
            assertEq(token.balanceOf(from, id), userMintAmounts[from][id] - transferAmount);
        }
    }

    function testBatchBalanceOf(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        uint256 minLength = min3(tos.length, ids.length, amounts.length);

        for (uint256 i = 0; i < minLength; i++) {
            tos[i] = tos[i] == address(0) ? address(0xBEEF) : tos[i];
            tos[i] = tos[i] == address(this) ? address(0xBEEF) : tos[i];
            tos[i] = tos[i] == address(token) ? address(0xBEEF) : tos[i];
        }

        address[] memory normalizedTos = new address[](minLength);
        uint256[] memory normalizedIds = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];
            address to = tos[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[to][id];

            normalizedTos[i] = to;
            normalizedIds[i] = id;

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            // We only want EOAs
            vm.assume(address(to).code.length == 0);
            token.mint(to, id, mintAmount, mintData);

            userMintAmounts[to][id] += mintAmount;
        }

        uint256[] memory balances = token.balanceOfBatch(normalizedTos, normalizedIds);

        for (uint256 i = 0; i < normalizedTos.length; i++) {
            assertEq(balances[i], token.balanceOf(normalizedTos[i], normalizedIds[i]));
        }
    }

    function testMintToZeroUnsafeRecipient(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        vm.expectRevert(bytes("UNSAFE_RECIPIENT"));
        token.mint(address(0), id, amount, data);
    }

    function testMintToNonERC155RecipientUnsafeRecipient(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData
    ) public {
        address recipient = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.mint(recipient, id, mintAmount, mintData);
    }

    function testMintToRevertingERC155RecipientReverts(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData
    ) public {
        address recipient = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.mint(recipient, id, mintAmount, mintData);
    }

    function testMintToWrongReturnDataERC155RecipientUnsafeRecipient(
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData
    ) public {
        address recipient = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.mint(recipient, id, mintAmount, mintData);
    }

    function test_RevertWhen_BurnInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 burnAmount,
        bytes memory mintData
    ) public {
        vm.assume(to != address(0) && to.code.length == 0);
        vm.assume(mintAmount != type(uint256).max);
        burnAmount = bound(burnAmount, mintAmount + 1, type(uint256).max);

        token.mint(to, id, mintAmount, mintData);
        vm.expectRevert();
        token.burn(to, id, burnAmount);
    }

    function test_RevertWhen_SafeTransferFromInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        vm.assume(mintAmount != type(uint256).max);
        transferAmount = bound(transferAmount, mintAmount + 1, type(uint256).max);

        token.mint(from, id, mintAmount, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeTransferFrom(from, to, id, transferAmount, transferData);
    }

    function test_RevertWhen_SafeTransferFromSelfInsufficientBalance(
        address to,
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        vm.assume(mintAmount != type(uint256).max);
        transferAmount = bound(transferAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), id, mintAmount, mintData);
        vm.expectRevert();
        token.safeTransferFrom(address(this), to, id, transferAmount, transferData);
    }

    function test_RevertWhen_SafeTransferFromToZero(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);
        vm.expectRevert();
        token.safeTransferFrom(address(this), address(0), id, transferAmount, transferData);
    }

    function test_RevertWhen_SafeTransferFromToNonERC155Recipient(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);
        address _to = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(address(this), _to, id, transferAmount, transferData);
    }

    function test_RevertWhen_SafeTransferFromToRevertingERC1155Recipient(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);
        address _to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(
            address(this),
            _to,
            id,
            transferAmount,
            transferData
        );
    }

    function test_RevertWhen_SafeTransferFromToWrongReturnDataERC1155Recipient(
        uint256 id,
        uint256 mintAmount,
        uint256 transferAmount,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        transferAmount = bound(transferAmount, 0, mintAmount);

        token.mint(address(this), id, mintAmount, mintData);
        address _to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert();
        token.safeTransferFrom(
            address(this),
            _to,
            id,
            transferAmount,
            transferData
        );
    }

    function test_RevertWhen_SafeBatchTransferInsufficientBalance(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        vm.assume(!(minLength == 0));

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            if (mintAmount == type(uint256).max) mintAmount = type(uint256).max - 1;
            uint256 transferAmount = bound(transferAmounts[i], mintAmount + 1, type(uint256).max);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeBatchTransferFrom(from, to, normalizedIds, normalizedTransferAmounts, transferData);
    }

    function test_RevertWhen_SafeBatchTransferFromToZero(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert();
        token.safeBatchTransferFrom(from, address(0), normalizedIds, normalizedTransferAmounts, transferData);
    }

    function test_RevertWhen_SafeBatchTransferFromToNonERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new NonERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(
            from,
            _to,
            normalizedIds,
            normalizedTransferAmounts,
            transferData
        );
    }

    function test_RevertWhen_SafeBatchTransferFromToRevertingERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new RevertingERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(
            from,
            _to,
            normalizedIds,
            normalizedTransferAmounts,
            transferData
        );
    }

    function test_RevertWhen_SafeBatchTransferFromToWrongReturnDataERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        address from = address(0xABCD);

        uint256 minLength = min3(ids.length, mintAmounts.length, transferAmounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedTransferAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[from][id];

            uint256 mintAmount = bound(mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = bound(transferAmounts[i], 0, mintAmount);

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = mintAmount;
            normalizedTransferAmounts[i] = transferAmount;

            userMintAmounts[from][id] += mintAmount;
        }

        token.batchMint(from, normalizedIds, normalizedMintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        address _to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert();
        token.safeBatchTransferFrom(
            from,
            _to,
            normalizedIds,
            normalizedTransferAmounts,
            transferData
        );
    }

    function test_RevertWhen_SafeBatchTransferFromWithArrayLengthMismatch(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory transferAmounts,
        bytes memory mintData,
        bytes memory transferData
    ) public {
        vm.assume(!(ids.length == transferAmounts.length));

        // The whole body must revert: either the setup batchMint (mismatched
        // ids/mintAmounts, etc.) or the safeBatchTransferFrom array-length mismatch.
        vm.expectRevert();
        this.batchMintThenBatchTransfer(to, ids, mintAmounts, transferAmounts, mintData, transferData);
    }

    function batchMintThenBatchTransfer(
        address to,
        uint256[] calldata ids,
        uint256[] calldata mintAmounts,
        uint256[] calldata transferAmounts,
        bytes calldata mintData,
        bytes calldata transferData
    ) external {
        address from = address(0xABCD);
        token.batchMint(from, ids, mintAmounts, mintData);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, to, ids, transferAmounts, transferData);
    }

    function test_RevertWhen_BatchMintToZero(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(0)][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[address(0)][id] += mintAmount;
        }

        vm.expectRevert();
        token.batchMint(address(0), normalizedIds, normalizedAmounts, mintData);
    }

    function test_RevertWhen_BatchMintToNonERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        NonERC1155Recipient to = new NonERC1155Recipient();

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        vm.expectRevert();
        token.batchMint(address(to), normalizedIds, normalizedAmounts, mintData);
    }

    function test_RevertWhen_BatchMintToRevertingERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        RevertingERC1155Recipient to = new RevertingERC1155Recipient();

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        vm.expectRevert();
        token.batchMint(address(to), normalizedIds, normalizedAmounts, mintData);
    }

    function test_RevertWhen_BatchMintToWrongReturnDataERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        WrongReturnDataERC1155Recipient to = new WrongReturnDataERC1155Recipient();

        uint256 minLength = min2(ids.length, amounts.length);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = bound(amounts[i], 0, remainingMintAmountForId);

            normalizedIds[i] = id;
            normalizedAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        vm.expectRevert();
        token.batchMint(address(to), normalizedIds, normalizedAmounts, mintData);
    }

    function test_RevertWhen_BatchMintWithArrayMismatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        vm.assume(!(ids.length == amounts.length));

        vm.expectRevert();
        token.batchMint(address(to), ids, amounts, mintData);
    }

    function test_RevertWhen_BatchBurnInsufficientBalance(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory burnAmounts,
        bytes memory mintData
    ) public {
        uint256 minLength = min3(ids.length, mintAmounts.length, burnAmounts.length);

        vm.assume(!(minLength == 0));
        // `to` must be a valid recipient so the setup batchMint succeeds; the
        // asserted revert comes from the subsequent insufficient-balance batchBurn.
        vm.assume(to != address(0) && to.code.length == 0);

        uint256[] memory normalizedIds = new uint256[](minLength);
        uint256[] memory normalizedMintAmounts = new uint256[](minLength);
        uint256[] memory normalizedBurnAmounts = new uint256[](minLength);

        for (uint256 i = 0; i < minLength; i++) {
            uint256 id = ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[to][id];

            normalizedIds[i] = id;
            normalizedMintAmounts[i] = bound(mintAmounts[i], 0, remainingMintAmountForId);
            if (normalizedMintAmounts[i] == type(uint256).max) normalizedMintAmounts[i] = type(uint256).max - 1;
            normalizedBurnAmounts[i] = bound(burnAmounts[i], normalizedMintAmounts[i] + 1, type(uint256).max);

            userMintAmounts[to][id] += normalizedMintAmounts[i];
        }

        token.batchMint(to, normalizedIds, normalizedMintAmounts, mintData);

        vm.expectRevert();
        token.batchBurn(to, normalizedIds, normalizedBurnAmounts);
    }

    function test_RevertWhen_BatchBurnWithArrayLengthMismatch(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory burnAmounts,
        bytes memory mintData
    ) public {
        vm.assume(!(ids.length == burnAmounts.length));

        // The whole body must revert: either the setup batchMint (e.g. mismatched
        // ids/mintAmounts, bad recipient) or the batchBurn array-length mismatch.
        // Route it through an external call so vm.expectRevert catches whichever fires.
        vm.expectRevert();
        this.batchMintThenBurn(to, ids, mintAmounts, burnAmounts, mintData);
    }

    function batchMintThenBurn(
        address to,
        uint256[] calldata ids,
        uint256[] calldata mintAmounts,
        uint256[] calldata burnAmounts,
        bytes calldata mintData
    ) external {
        token.batchMint(to, ids, mintAmounts, mintData);
        token.batchBurn(to, ids, burnAmounts);
    }

    function test_RevertWhen_BalanceOfBatchWithArrayMismatch(address[] memory tos, uint256[] memory ids) public {
        vm.assume(!(tos.length == ids.length));

        vm.expectRevert();
        token.balanceOfBatch(tos, ids);
    }
}

