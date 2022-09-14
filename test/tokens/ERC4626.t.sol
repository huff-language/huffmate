// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { ERC20 } from "solmate/tokens/ERC20.sol";

interface IERC4626 {
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

contract ERC4626Test is Test {
    IERC4626 token;
    ERC20 erc20Token;

    function setUp() public {
        // Deploy test erc20 token
        erc20Token = new TestToken(10_000 * 10**18);

        // Deploy the ERC4626
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC4626Wrappers.huff");
        token = IERC4626(
            HuffDeployer
                .config()
                .with_code(wrapper_code)
                .with_args(bytes.concat(abi.encode("Token"), abi.encode("TKN"), abi.encode(address(erc20Token))))
                .deploy("tokens/ERC4626")
        );
    }

    /// @notice Test the ERC721 Metadata
    function testMetadata() public {
        assertEq(keccak256(abi.encode(token.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(token.symbol())), keccak256(abi.encode("TKN")));
        assertEq(keccak256(abi.encode(token.tokenURI(1))), keccak256(abi.encode("")));
        assertEq(token.decimals(), 18);
    }
}

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MDT", "Merk", 18) {
        _mint(msg.sender, initialSupply);
    }
}