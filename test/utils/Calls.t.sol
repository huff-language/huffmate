// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface ICalls {
    function callFunc() external;
    function staticcallFunc() external;
    function callcodeFunc() external;
}

contract CallsTest is Test {
    ICalls calls;

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/CallWrappers.huff");
        calls = ICalls(HuffDeployer.deploy_with_code("utils/Calls", wrapper_code));
    }

    function testCall() public {
        calls.callFunc();
    }

    function testStaticCall() public {
        calls.staticcallFunc();
    }

    function testCallCode() public {
        calls.callcodeFunc();
    }
}