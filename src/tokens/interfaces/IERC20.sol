// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface TSOwnable {
    function owner() external returns (address);
    function pendingOwner() external returns (address);
    function setPendingOwner(address) external;
    function acceptOwnership() external;

    event NewOwner(address indexed,address indexed);
    event NewPendingOwner(address indexed,address indexed);
}

/// @notice Interface of the ERC20 standard as defined in the EIP.
/// @author Adapted from OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`)
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Returns the name of token
    function name() external view returns (string memory);

    /// @dev Returns the symbol of token
    function symbol() external view returns (string memory);

    /// @dev Returns the symbol of token
    function decimals() external view returns (uint256);

    /// @dev Returns the domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @dev Permit
    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external;

    /// @dev Permit Nonces
    function nonces(address) external returns (uint256);

    /// @dev Returns the amount of tokens in existence
    function totalSupply() external view returns (uint256);

    /// @dev Returns the amount of tokens owned by `account`
    function balanceOf(address account) external view returns (uint256);

    /// @dev Creates new token.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMintableERC20 is IERC20 {
    /// @dev Moves `amount` tokens from the caller's account to `to`.
    function mint(address to, uint256 amount) external;

    /// @dev Removes `amount` tokens from the `from` account.
    function burn(address from, uint256 amount) external;
}

interface IERC20Ownable is TSOwnable, IERC20 {}
