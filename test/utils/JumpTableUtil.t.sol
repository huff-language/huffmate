// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";

interface IJumpTableUtil {
    function getJumpdestMem(uint256) external view returns(uint256);
    function getJumpdestStack(uint256) external view returns(uint256);
    function getJumpdestMemPacked(uint256) external view returns(uint256);
    function getJumpdestStackPacked(uint256) external view returns(uint256);
}

contract JumpTableUtilTest is Test {
    uint constant FIRST_LABEL_PC = 147;

    IJumpTableUtil jtUtil;

    function setUp() public {
        /// @notice deploy a new instance of IJumpTableUtil by
        /// passing in the address of the deployed Huff contract
        string memory wrapper_code = vm.readFile("test/utils/mocks/JumpTableUtilWrappers.huff");
        jtUtil = IJumpTableUtil(HuffDeployer.deploy_with_code("utils/JumpTableUtil", wrapper_code));
    }

    function testGetJumpdestFromJT_Mem() public {
        for (uint i; i < 4; i++) {
            uint jumpdest = jtUtil.getJumpdestMem(i);
            assertEq(jumpdest, FIRST_LABEL_PC + i);
        }
    }

    function testGetJumpdestFromJT_Stack() public {
        for (uint i; i < 4; i++) {
            uint jumpdest = jtUtil.getJumpdestStack(i);
            assertEq(jumpdest, FIRST_LABEL_PC + i);
        }
    }

    function testGetJumpdestFromPackedJT_Mem() public {
        for (uint i; i < 4; i++) {
            uint jumpdest = jtUtil.getJumpdestMemPacked(i);
            assertEq(jumpdest, FIRST_LABEL_PC + i);
        }
    }

    function testGetJumpdestFromPackedJT_Stack() public {
        for (uint i; i < 4; i++) {
            uint jumpdest = jtUtil.getJumpdestStackPacked(i);
            assertEq(jumpdest, FIRST_LABEL_PC + i);
        }
    }
}