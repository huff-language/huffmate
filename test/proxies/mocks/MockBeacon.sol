
pragma solidity 0.8.15;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

contract MockBeacon is IBeacon {
    address public implementation_;

    constructor(address implementation) {
        implementation_ = implementation;
    }

    function implementation() external view override returns (address) {
        return implementation_;
    }
} 