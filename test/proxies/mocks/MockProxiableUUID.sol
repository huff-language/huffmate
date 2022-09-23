pragma solidity 0.8.15;

import { MockERC1155 } from "solmate/test/utils/mocks/MockERC1155.sol";

contract MockProxiableUUID is MockERC1155 {
    bytes32 public uuid;

    bytes32 constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function proxiableUUID() external view returns (bytes32 slot) {
        return _IMPLEMENTATION_SLOT;
    }
}