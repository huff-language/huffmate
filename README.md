<img align="right" width="150" height="150" top="100" src="./assets/huff.jpg">

# huffmate • [![ci](https://github.com/huff-language/huffmate/actions/workflows/test.yml/badge.svg)](https://github.com/huff-language/huffmate/actions/workflows/test.yml) [![version](https://img.shields.io/badge/version-v1.1-ff69b4)](https://github.com/huff-language/huffmate/releases/tag/v1.1) [![license](https://img.shields.io/badge/License-MIT-orange.svg?label=license)](https://opensource.org/licenses/MIT) ![Discord](https://img.shields.io/discord/980519274600882306?color=blue)

A set of **modern**, **opinionated**, and **secure** [Huff](https://github.com/huff-language) contracts.

> **Warning**
>
> These contracts are **unaudited** and are not recommended for use in production.
>
> Although contracts have been rigorously reviewed, this is **experimental software** and is provided on an "as is" and "as available" basis.
> We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

### Usage

**Recommended** To install with [**Foundry**](https://github.com/foundry-rs/foundry):

```sh
forge install huff-language/huffmate
```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install @pentagonxyz/huffmate
```

### Contracts

```
auth
├─ Auth — "Flexible and updatable auth pattern"
├─ NonPayable — "Modifier Macro that reverts the tx when msg.value > 0"
├─ OnlyContract — "Basic Macro that reverts when the sender is an EOA"
├─ Owned — "Simple single owner authorization"
├─ RolesAuthority — "Role based Authority that supports up to 256 roles"
data-structures
├─ Arrays — "Memory translation handlers for arrays"
├─ Hashmap — "Simple mapping utilities for 32 byte words"
├─ Bytes — "Helpers for working with Bytes"
proxies
├─ Clones — "Clones library for deploying minimal proxy contracts"
├─ Proxy — "Minimal ERC1967-compliant + upgradeable proxy contract"
mechanisms
|  ├─ huff-clones — "Library for creating clone contracts with immutable arguments"
|  |  ├─ ExampleClone — "Example clones-with-immutable-args clone contract"
|  |  ├─ ExampleCloneFactory — "Example clones-with-immutable-args factory contract"
|  |  ├─ HuffClone — "Clones-with-immutable-args Clone Instance"
|  |  └─ HuffCloneLib — "Library for creating a HuffClone"
|  └─ huff-vrgda — "Variable Rate Gradual Dutch Auctions written in Huff"
|      ├─ LinearVRGDA — "VRGDA with a linear issuance curve"
|      ├─ LogisticVRGDA — "VRGDA with a logistic issuance curve"
|      └─ VRGDA — "Sell tokens roughly according to an issuance schedule"
math
├─ FixedPointMath — "Arithmetic library with operations for fixed-point numbers"
├─ Math — "Refactored, common arithmetic macros"
├─ SafeMath — "Safe Wrappers over primitive arithmetic operations"
├─ Trigonometry — "Basic trigonometry functions where inputs and outputs are integers"
tokens
├─ ERC20 — "Modern and gas efficient ERC20 + EIP-2612 implementation"
├─ ERC721 — "Modern, minimalist, and gas efficient ERC721 implementation"
├─ ERC1155 — "Minimalist and gas efficient standard ERC1155 implementation"
├─ ERC4626 — "Minimal ERC4626 tokenized Vault implementation"
utils
├─ Address — "Simple Utils for working with addresses"
├─ BitPackLib — "Efficient bit packing library"
├─ Calls — "Minimal wrappers for constructing calls to other contracts"
├─ CommonErrors — "Wrappers for reverting with common error messages"
├─ CREATE3 — "Deploy to deterministic addresses without the initcode factor"
├─ ECDSA — "An optimised ECDSA wrapper"
├─ ERC1155Receiver — "A minimal interface for receiving ERC1155 tokens"
├─ ERC20Transfer — "Efficient ERC20 transfer wrappers"
├─ Errors — "Custom error utilities"
├─ Ethers — "Utilities for working with ether at a low level"
├─ JumpTableUtil — "Utility macros for retrieving jumpdest pcs from jump tables"
├─ LibBit — "A library ported from solady for bit twiddling operations"
├─ MerkleProofLib — "Gas optimized merkle proof verification library"
├─ Multicallable — "Enables a single call to call multiple methods within a contract"
├─ Pausable — "An implementation of the Pausable standard"
├─ ReentrancyGuard — "Gas optimized reentrancy protection for smart contracts"
├─ Refunded — "Efficient gas refunds distributed through a modifier"
├─ SafeTransferLib — "Safe ETH and ERC20 transfer library that gracefully handles missing return values"
├─ Shuffling — "Refactored algorithms for shuffling and other bitwise algorithms"
└─ SSTORE2 — "Faster & cheaper contract key-value storage for Ethereum Contracts"
└─ Ternary — "A collection of ternary operations with abstracted conditional logic"
└─ TSOwnable — "An Ownable Implementation using Two-Step Transfer Pattern"
```

### Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:

- [solmate](https://github.com/transmissions11/solmate)
- [solady](https://github.com/Vectorized/solady)
- [zolidity](https://github.com/z0r0z/zolidity)
- [huff-examples](https://github.com/huff-language/huff-examples)
- [huff-rs](https://github.com/huff-language/huff-rs)
- [huff-clones](https://github.com/clabby/huff-clones)
- [huff-vrgda](https://github.com/cheethas/huff-vrgda)
- [huff-tests](https://github.com/huff-language/huff-tests-action)
- [erc721h](https://github.com/philogy/erc721h)
- [Gnosis](https://github.com/gnosis/gp-v2-contracts)
- [Uniswap](https://github.com/Uniswap/uniswap-lib)
- [Dappsys](https://github.com/dapphub/dappsys)
- [Dappsys V2](https://github.com/dapp-org/dappsys-v2)
- [0xSequence](https://github.com/0xSequence)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
