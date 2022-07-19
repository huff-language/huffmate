// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface ERC721 {
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
    ERC721 erc721;

    function setUp() public {
        HuffConfig config = HuffDeployer.config();
        erc721 = ERC721(config.deploy("tokens/ERC721"));
    }
}
