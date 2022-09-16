<img align="right" width="150" height="150" top="100" src="./assets/huff.jpg">

# huffmate • [![ci](https://github.com/pentagonxyz/huffmate/actions/workflows/test.yml/badge.svg)](https://github.com/pentagonxyz/huffmate/actions/workflows/test.yml) [![license](https://img.shields.io/badge/License-MIT-blue.svg?label=license)](https://opensource.org/licenses/MIT) ![Discord](https://img.shields.io/discord/980519274600882306)

A set of **modern**, **opinionated**, and **secure** [Huff](https://github.com/huff-language) contracts.

> **Warning**
>
> These contracts are **unaudited** and are not recommended for use in production.
>
> Although contracts have been rigorously reviewed, this is **experimental software** and is provided on an "as is" and "as available" basis.
> We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.


## Warning: Be cautious

Huffmate is still a work in progress and the majority of contracts have yet to be completed and audited. We do not give any warranties and will not be liable for any loss incurred through any use of this codebase.

Use these contracts at your own risk!


### Usage

To install with [**Foundry**](https://github.com/foundry-rs/foundry):

```sh
forge install pentagonxyz/huffmate
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install @pentagonxyz/huffmate
```


### Contracts

```ml
auth
├─ Auth — "Flexible and updatable auth pattern"
├─ NonPayable — "Modifier Macro that reverts the tx when msg.value > 0"
├─ OnlyContract — "Basic Macro that reverts when the sender is an EOA"
├─ Owned — "Simple single owner authorization"
├─ RolesAuthority — "Role based Authority that supports up to 256 roles"
data-structures
├─ Arrays — "Memory translation handlers for arrays"
├─ Bytes — TODO
├─ Hashmap — "Simple mapping utilities for 32 byte words"
factories
├─ Factory — TODO
├─ ProxyFactory — TODO
math
├─ FixedPointMath — "Arithmetic library with operations for fixed-point numbers"
├─ Math — "Refactored, common arithmetic macros"
├─ SafeMath — "Safe Wrappers over primitive arithmetic operations"
├─ Trigonometry — "Basic trigonometry functions where inputs and outputs are integers"
tokens
├─ ERC20 — "Modern and gas efficient ERC20 + EIP-2612 implementation"
├─ ERC721 — "Modern, minimalist, and gas efficient ERC721 implementation"
├─ ERC1155 — "Minimalist and gas efficient standard ERC1155 implementation"
├─ ERC4626 — TODO - "Minimal ERC4626 tokenized Vault implementation"
utils
├─ Calls — "Minimal wrappers for constructing calls to other contracts"
├─ BitPackLib — "Efficient bit packing library"
├─ CustomErrors — "Wrappers for reverting with common error messages"
├─ ERC1155Receiver — "A minimal interface for receiving ERC1155 tokens"
├─ Errors — "Custom error utilities"
├─ JumpTableUtil — "Utility macros for retrieving jumpdest pcs from jump tables"
├─ LibBit — "A library ported from solady for bit twiddling operations"
├─ MerkleProofLib — "Gas optimized merkle proof verification library"
├─ Multicallable — "Enables a single call to call multiple methods within a contract"
├─ TSOwnable — "An Ownable Implementation using Two-Step Transfer Pattern"
├─ ReentrancyGuard — "Gas optimized reentrancy protection for smart contracts"
├─ SSTORE2 — TODO
```


### Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:

- [solmate](https://github.com/transmissions11/solmate)
- [huff-examples](https://github.com/huff-language/huff-examples)
- [huff-rs](https://github.com/huff-language/huff-rs)
- [huff-clones](https://github.com/clabby/huff-clones)
- [huff-tests](https://github.com/abigger87/huff-tests)
- [erc721h](https://github.com/philogy/erc721h)
- [Gnosis](https://github.com/gnosis/gp-v2-contracts)
- [Uniswap](https://github.com/Uniswap/uniswap-lib)
- [Dappsys](https://github.com/dapphub/dappsys)
- [Dappsys V2](https://github.com/dapp-org/dappsys-v2)
- [0xSequence](https://github.com/0xSequence)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
