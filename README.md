<img align="right" width="150" height="150" top="100" src="./assets/huff.jpg">

# huffmate • [![ci](https://github.com/pentagonxyz/huffmate/actions/workflows/test.yml/badge.svg)](https://github.com/pentagonxyz/huffmate/actions/workflows/test.yml) [![license](https://img.shields.io/badge/License-Apache_2.0-blue.svg?label=license)](https://opensource.org/licenses/Apache-2.0) ![Discord](https://img.shields.io/discord/980519274600882306)

A set of **modern**, **opinionated**, and **secure** [Huff](https://github.com/huff-language) contracts.

## Warning: Be cautious
Huffmate is still a work in progress and the majority of contracts have yet to be completed and audited. We do not give any warranties and will not be liable for any loss incurred through any use of this codebase.

Use these contracts at your own risk!

## Usage

To install with [**Foundry**](https://github.com/foundry-rs/foundry):

```sh
forge install pentagonxyz/huffmate
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install @pentagonxyz/huffmate
```


## Contracts

```ml
auth
├─ Auth — "Flexible and updatable auth pattern"
├─ NonPayable — "Modifier Macro that reverts the tx when msg.value > 0"
├─ OnlyContract — "Basic Macro that reverts when the sender is an EOA"
├─ Owned — "Simple single owner authorization"
├─ RolesAuthority — "Role based Authority that supports up to 256 roles"
data-structures
├─ Arrays - "Memory translation handlers for arrays"
├─ Bytes — TODO
├─ Hashmap - "Simple mapping utilities for 32 byte words"
factories
├─ Factory - TODO
├─ ProxyFactory — TODO
math
├─ FixedPointMath - "Arithmetic library with operations for fixed-point numbers"
├─ Math — "Refactored, common arithmetic macros"
├─ SafeMath — "Safe Wrappers over primitive arithmetic operations"
tokens
├─ ERC20 — "Modern and gas efficient ERC20 + EIP-2612 implementation"
├─ ERC721 — TODO - "Modern, minimalist, and gas efficient ERC721 implementation"
├─ ERC1155 — TODO -"Minimalist and gas efficient standard ERC1155 implementation"
├─ ERC4626 — TODO - "Minimal ERC4626 tokenized Vault implementation"
utils
├─ Calls - TODO
├─ Data — TODO
├─ MerkleProofLib — "Gas optimized merkle proof verification library"
├─ Multicallable — "Enables a single call to call multiple methods within a contract."
├─ ReentrancyGuard — TODO
├─ SSTORE2 — TODO
```


## Safety

Although contracts have been rigorously reviewed, this is **experimental software** and is provided on an "as is" and "as available" basis.

We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.


## Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:

- [solmate](https://github.com/Rari-Capital/solmate)
- [huff-examples](https://github.com/huff-language/huff-examples)
- [Gnosis](https://github.com/gnosis/gp-v2-contracts)
- [Uniswap](https://github.com/Uniswap/uniswap-lib)
- [Dappsys](https://github.com/dapphub/dappsys)
- [Dappsys V2](https://github.com/dapp-org/dappsys-v2)
- [0xSequence](https://github.com/0xSequence)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
