// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";

interface IERC20 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function tokenURI(uint256) external returns (string memory);
    function decimals() external returns (uint256);

    function mint(address, uint256) payable external;
    function burn(uint256) external;

    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256) external;
    function safeTransferFrom(address, address, uint256, bytes calldata) external;

    function approve(address, uint256) external;
    function setApprovalForAll(address, bool) external;

    function getApproved(uint256) external returns (address);
    function isApprovedForAll(address, address) external returns (bool);
    function ownerOf(uint256) external returns (address);
    function balanceOf(address) external returns (uint256);
    function supportsInterface(bytes4) external returns (bool);
}

interface IERC4626 is IERC20 {
    function asset() external view returns (address);
}

contract ERC4626Test is Test {
    IERC4626 vault;
    ERC20 underlying;

    function setUp() public {
        // Deploy test erc20 token
        underlying = new TestToken(10_000 * 10**18);

        // Deploy the ERC4626
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC4626Wrappers.huff");
        vault = IERC4626(
            HuffDeployer
                .config()
                .with_code(wrapper_code)
                .with_args(bytes.concat(abi.encode("Token"), abi.encode("TKN"), abi.encode(address(underlying))))
                .deploy("tokens/ERC4626")
        );
    }

    /// @notice Test the ERC721 Metadata
    function testMetadata() public {
        assertEq(keccak256(abi.encode(vault.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(vault.symbol())), keccak256(abi.encode("TKN")));
        assertEq(vault.decimals(), 18);
        assertEq(vault.asset(), address(underlying));
    }

    /// @notice Test Deposits and Withdrawals
    function testSingleDepositWithdraw(uint128 amount) public {
        if (amount == 0) amount = 1;

        uint256 aliceUnderlyingAmount = amount;

        address alice = address(0xABCD);

        underlying.mint(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice);

        assertEq(vault.afterDepositHookCalledCounter(), 1);

        // Expect exchange rate to be 1:1 on initial deposit.
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);

        vm.prank(alice);
        vault.withdraw(aliceUnderlyingAmount, alice, alice);

        assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        assertEq(vault.totalAssets(), 0);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }
}

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MDT", "Merk", 18) {
        _mint(msg.sender, initialSupply);
    }
}