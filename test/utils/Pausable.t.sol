// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";


interface IPausable {
    function isPaused() external view returns (bool);
    function pause() external;
    function unpause() external;
}



contract PausableTest is Test {
    IPausable pausable;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/PausableWrappers.huff");
        pausable = IPausable(HuffDeployer.deploy_with_code("utils/Pausable", wrapper_code));
    }

    function testIsPausedByDefault() public {
        assertEq(pausable.isPaused(), false);
    }

    function testPauseUnPause() public {
        pausable.pause();
        assertEq(pausable.isPaused(), true);

        pausable.unpause();
        assertEq(pausable.isPaused(), false);
    }
    
    function testUnpauseWhenUnpaused() public {
        assertEq(pausable.isPaused(), false);

        vm.expectRevert();
        pausable.unpause();
    }

    function testPauseWhenPaused() public {
        pausable.pause();
        assertEq(pausable.isPaused(), true);

        vm.expectRevert();
        pausable.pause();
    }


}