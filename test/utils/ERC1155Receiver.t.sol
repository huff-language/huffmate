// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC1155ReceiverTest is Test {
    IERC1155Receiver receiver;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/ERC1155ReceiverWrappers.huff");
        receiver = IERC1155Receiver(HuffDeployer.deploy_with_code("utils/ERC1155Receiver", wrapper_code));
    }

    function testOnERC1155ReceivedReturnsSelector() public {
        bytes4 ret = receiver.onERC1155Received(address(0xBEEF), address(0xCAFE), 1337, 1, "");
        assertEq(ret, IERC1155Receiver.onERC1155Received.selector);
    }
}
