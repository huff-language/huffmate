pragma solidity 0.8.15;


import { MockERC1155 } from "solmate/test/utils/mocks/MockERC1155.sol";


contract NotUUPSMockProxiableUUID is MockERC1155 {
    bytes32 public uuid;

    function proxiableUUID() external view returns (bytes32 slot) {
        assembly {
            slot := uuid.slot
        }
    }
}
