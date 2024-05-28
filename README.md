# WeRa Contracts

This repository contains the core implementation of WeRa's smart contracts.

## Components

1. **Diamond Proxy**:
    - `src/diamond/Diamond.sol`
    - Implements modular and upgradable contract architecture.

2. **WeP ERC20 Token**:
    - `src/token/WeP.sol`
    - Mintable and burnable ERC20 token with OpenZeppelin ERC20Votes.

3. **Staking Contract**:
    - `src/staking/facets/WeRaStakingFacet.sol`
    - Manages staking with a treasury, minting and burning WeP tokens 1:1 with a stablecoin.

4. **Test Stablecoin**:
    - `src/test/TokenMock.sol`
    - Mock stablecoin for testing purposes.

5. **Faucet for Stablecoin**:
    - `src/test/TokenFaucet.sol`
    - Provides test stablecoins to users.

## Summary

This core implementation provides foundational token and staking mechanics, leveraging the Diamond Proxy pattern for flexibility and upgradability.

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
