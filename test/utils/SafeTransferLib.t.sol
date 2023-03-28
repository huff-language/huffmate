// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MockERC20} from "./safe-transfer-lib-mocks/mocks/MockERC20.sol";
import {RevertingToken} from "./safe-transfer-lib-mocks/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./safe-transfer-lib-mocks/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./safe-transfer-lib-mocks/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./safe-transfer-lib-mocks/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./safe-transfer-lib-mocks/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsGarbageToken} from "./safe-transfer-lib-mocks/weird-tokens/ReturnsGarbageToken.sol";
import {ReturnsTooLittleToken} from "./safe-transfer-lib-mocks/weird-tokens/ReturnsTooLittleToken.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface ISafeTransferLib {
    function safeTransferETH(address to, uint256 amount) external;

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) external;
}

contract SafeTransferLibTest is Test {
    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsGarbageToken returnsGarbage;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;
    ISafeTransferLib public SafeTransferLib;

    error ETHTransferFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApproveFailed();

    function setUp() public {
        string memory wrapper_code = vm.readFile("test/utils/mocks/SafeTransferLibWrappers.huff");
        SafeTransferLib = ISafeTransferLib(HuffDeployer.config().with_code(wrapper_code).deploy("utils/SafeTransferLib"));

        vm.deal(address(SafeTransferLib), 1000 ether);

        vm.startPrank(address(SafeTransferLib));
        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(SafeTransferLib), type(uint256).max);

        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsGarbage = new ReturnsGarbageToken();
        returnsTooLittle = new ReturnsTooLittleToken();
        vm.stopPrank();
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testTransferWithNonContract() public {
        SafeTransferLib.safeTransfer(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(address(missingReturn), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithNonContract() public {
        SafeTransferLib.safeTransferFrom(address(0xBADBEEF), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testApproveWithNonContract() public {
        SafeTransferLib.safeApprove(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferETH() public {
        SafeTransferLib.safeTransferETH(address(0xBEEF), 1e18);
    }

    function testTransferRevertSelector() public {
        vm.expectRevert(TransferFailed.selector);
        this.testFailTransferWithReturnsFalse();
    }

    function testTransferFromRevertSelector() public {
        vm.expectRevert(TransferFromFailed.selector);
        this.testFailTransferFromWithReturnsFalse();
    }

    function testApproveRevertSelector() public {
        vm.expectRevert(ApproveFailed.selector);
        this.testFailApproveWithReturnsFalse();
    }

    function testTransferETHRevertSelector() public {
        vm.expectRevert(ETHTransferFailed.selector);
        this.testFailTransferETHToContractWithoutFallback();
    }

    function testFailTransferWithReturnsFalse() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReverting() public {
        verifySafeTransfer(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReturnsTooLittle() public {
        verifySafeTransfer(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsFalse() public {
        verifySafeTransferFrom(address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReverting() public {
        verifySafeTransferFrom(address(reverting), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsTooLittle() public {
        verifySafeTransferFrom(address(returnsTooLittle), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsFalse() public {
        verifySafeApprove(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReverting() public {
        verifySafeApprove(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsTooLittle() public {
        verifySafeApprove(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFuzzTransferWithMissingReturn(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function testFuzzTransferWithStandardERC20(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function testFuzzTransferWithReturnsTooMuch(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTooMuch), to, amount);
    }

    function testFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFuzzTransferWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(nonContract != HEVM_ADDRESS && nonContract != CONSOLE);

        SafeTransferLib.safeTransfer(nonContract, to, amount);
    }

    function testFailTransferETHToContractWithoutFallback() public {
        SafeTransferLib.safeTransferETH(address(this), 1e18);
    }

    function testFuzzTransferFromWithMissingReturn(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function testFuzzTransferFromWithStandardERC20(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function testFuzzTransferFromWithReturnsTooMuch(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount);
    }

    function testFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFuzzTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(nonContract != HEVM_ADDRESS && nonContract != CONSOLE);

        SafeTransferLib.safeTransferFrom(nonContract, from, to, amount);
    }

    function testFuzzApproveWithMissingReturn(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(missingReturn), to, amount);
    }

    function testFuzzApproveWithStandardERC20(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(erc20), to, amount);
    }

    function testFuzzApproveWithReturnsTooMuch(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTooMuch), to, amount);
    }

    function testFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFuzzApproveWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(nonContract != HEVM_ADDRESS && nonContract != CONSOLE);

        SafeTransferLib.safeApprove(nonContract, to, amount);
    }

    function testFuzzTransferETH(
        address recipient,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        vm.assume(uint256(uint160(recipient)) > 18 && recipient.code.length == 0 && recipient != msg.sender);
        vm.assume(recipient != HEVM_ADDRESS && recipient != CONSOLE);

        amount = bound(amount, 0, address(SafeTransferLib).balance);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    function testFailFuzzTransferWithReturnsFalse(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsFalse), to, amount);
    }

    function testFailFuzzTransferWithReverting(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(reverting), to, amount);
    }

    function testFailFuzzTransferWithReturnsTooLittle(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzTransferWithReturnsTwo(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTwo), to, amount);
    }

    function testFailFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferFromWithReturnsFalse(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount);
    }

    function testFailFuzzTransferFromWithReverting(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(reverting), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTooLittle(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTwo(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount);
    }

    function testFailFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFailFuzzApproveWithReturnsFalse(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsFalse), to, amount);
    }

    function testFailFuzzApproveWithReverting(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(reverting), to, amount);
    }

    function testFailFuzzApproveWithReturnsTooLittle(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzApproveWithReturnsTwo(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTwo), to, amount);
    }

    function testFailFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferETHToContractWithoutFallback(uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        SafeTransferLib.safeTransferETH(address(this), amount);
    }

    function testSelfTransferStandardErc20(uint256 amount) public {
        address to = address(SafeTransferLib);

        uint256 preBal = erc20.balanceOf(to);
        SafeTransferLib.safeTransfer(address(erc20), to, amount);
        uint256 postBal = erc20.balanceOf(to);

        assertEq(preBal, postBal);
    }

    function verifySafeTransfer(
        address token,
        address to,
        uint256 amount
    ) public {
        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransfer(address(token), to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (to == address(SafeTransferLib)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) public {
        forceApprove(token, from, address(SafeTransferLib), amount);

        // We cast to MissingReturnToken here because it won't check
        // that there was return data, which accommodates all tokens.
        vm.prank(address(SafeTransferLib));
        MissingReturnToken(token).transfer(from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransferFrom(token, from, to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeApprove(
        address token,
        address to,
        uint256 amount
    ) public {
        SafeTransferLib.safeApprove(address(token), to, amount);

        assertEq(ERC20(token).allowance(address(SafeTransferLib), to), amount);
    }

    function forceApprove(
        address token,
        address from,
        address to,
        uint256 amount
    ) public {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }

    function garbageIsGarbage(bytes memory garbage) public pure returns (bool result) {
        assembly {
            result := and(or(lt(mload(garbage), 32), iszero(eq(mload(add(garbage, 0x20)), 1))), gt(mload(garbage), 0))
        }
    }

    modifier brutalizeMemory(bytes memory brutalizeWith) {
        /// @solidity memory-safe-assembly
        assembly {
            // Fill the 64 bytes of scratch space with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    64, // Copy enough to only fill the scratch space.
                    0, // Store the return value in the scratch space.
                    64 // Scratch space is only 64 bytes in size, we don't want to write further.
                )
            )

            let size := add(mload(brutalizeWith), 32) // Add 32 to include the 32 byte length slot.

            // Fill the free memory pointer's destination with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    size, // We want to pass the length of the bytes.
                    mload(0x40), // Store the return value at the free memory pointer.
                    size // Since the precompile just returns its input, we reuse size.
                )
            )
        }

        _;
    }
}
