# custom-sol

Custom-sol is a collection of Solidity contract snippets and examples for use in Ethereum blockchain development. It includes a variety of contracts for common use cases, such as ERC20 tokens, crowdsales, and voting systems, as well as more specialized contracts for things like on-chain random number generation and multisignature wallets.

The contracts in this repository are intended to be modular and easy to use, with extensive comments and documentation to help developers understand how each contract works. They are also thoroughly tested using Solidity's built-in testing features and continuous integration tools to ensure that they are of high quality and ready for use in production environments.

## Internal Modules

The `contracts` folder contains the following internal modules:

- `BasicToken.sol`: A basic ERC20 token contract.
- `Crowdsale.sol`: A contract for conducting crowdsales of tokens.
- `Random.sol`: A contract for generating random numbers on-chain.
- `Voting.sol`: A contract for conducting votes using ERC20 tokens as votes.
- `MultiSigWallet.sol`: A multisignature wallet contract that allows multiple parties to control the funds in the wallet.

## Getting Started

To get started using the contracts in this repository, you will need to have a basic understanding of Solidity and the Ethereum blockchain. You will also need to install the necessary tools for testing and deploying contracts, such as [Yarn](https://yarnpkg.com/getting-started/install) and [Hardhat](https://hardhat.org/getting-started/).

Once you have your environment set up, you can install the necessary dependencies by running the following command in the root directory of the repository:
```
yarn
```

Next, you can compile the contracts by running the following command:
```
yarn compile
```

This will compile the contracts and output the artifacts to the `build/contracts` directory.

You can then use a tool like Truffle to test and deploy the contracts to the Ethereum blockchain.

## Contributing

We welcome contributions to custom-sol from the community! If you have a contract snippet or example that you think would be useful to others, we encourage you to submit a pull request. Please make sure to follow our contribution guidelines and to thoroughly test your changes before submitting.

## License

Custom-sol is released under the MIT License. See the [LICENSE](LICENSE) file for more information.