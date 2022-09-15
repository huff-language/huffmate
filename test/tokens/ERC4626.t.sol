// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

interface IERC20 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function tokenURI(uint256) external returns (string memory);
    function totalSupply() external returns (uint256);
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

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
}

interface MockERC4626 is IERC4626 {
    function beforeWithdrawHookCalledCounter() external returns (uint256);
    function afterDepositHookCalledCounter() external returns (uint256);
}

contract ERC4626Test is Test {
    MockERC4626 vault;
    TestToken underlying;

    function setUp() public {
        // Deploy test erc20 token
        underlying = new TestToken(10_000 ** 18);

        // Deploy the ERC4626
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC4626Wrappers.huff");
        vault = MockERC4626(
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

contract TestToken is MockERC20 {
    constructor(uint256 initialSupply) MockERC20("Mock Token", "TKN", 18) {
        _mint(msg.sender, initialSupply);
    }
}