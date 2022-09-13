// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface IERC721 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function tokenURI(uint256) external returns (string memory);

    function mint(address,uint256) external;
    function transfer(address,uint256) external;
    function transferFrom(address,address,uint256) external;
    function approve(address,uint256) external;
    function setApprovalForAll(address,bool) external;

    function getApproved(uint256) external returns (address);
    function isApprovedForAll(address,address) external returns (uint256);
    function ownerOf(uint256) external returns (address);
    function balanceOf(address) external returns (uint256);
    function supportsInterface(bytes4) external returns (bool);
}

contract ERC721Test is Test {
    IERC721 erc721;

    function setUp() public {
        // Deploy the ERC721
        string memory wrapper_code = vm.readFile("test/tokens/mocks/ERC721Wrapper.huff");
        erc721 = IERC721(HuffDeployer.config().with_code(wrapper_code).deploy("tokens/ERC721"));
    }

    /// @notice Test the ERC721 Metadata
    function testMetadata() public {
        assertEq(keccak256(abi.encode(erc721.name())), keccak256(abi.encode("Token")));
        assertEq(keccak256(abi.encode(erc721.symbol())), keccak256(abi.encode("TKN")));
    }
}
