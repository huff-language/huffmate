pragma solidity 0.8.15;

/// @dev Used to test proxies that they can both receive and return data
contract MockReturner {

    function returnBytes(bytes calldata value) public pure returns (bytes calldata) {
        return value;
    }

    function returnUint(uint256 value) public pure returns (uint256) {
        return value;
    }

    function returnAddress(address value) public pure returns (address) {
        return value;
    }
}