// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

// Mock Interface
interface IGuard {
    function state() external view returns (uint256);
    function lock() external;
    function unlock() external;
}

contract ReentranctGuardTest is Test {
    IGuard guard;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/ReentrancyGuardWrappers.huff");
        guard = IGuard(HuffDeployer.deploy_with_code("utils/ReentrancyGuard", wrapper_code));
    }

    /// @notice Test locking
    function testLocking() public {
        guard.unlock();
        uint256 state = guard.state();
        assertEq(state, 1);

        // We should remain unlocked
        guard.unlock();
        state = guard.state();
        assertEq(state, 1);

        // Let's lock
        guard.lock();
        state = guard.state();
        assertEq(state, 2);

        // We should be able to unlock
        guard.unlock();
        state = guard.state();
        assertEq(state, 1);

        // We cannot lock twice
        guard.lock();
        state = guard.state();
        assertEq(state, 2);

        vm.expectRevert(bytes("REENTRANCY"));
        guard.lock();
    }

}
