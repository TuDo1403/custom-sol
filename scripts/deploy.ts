import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

async function main() {
    // const Factory: ContractFactory = await ethers.getContractFactory("UniswapV3Factory");
    // console.log({ Factory });
    // const factory: Contract = await Factory.deploy();

    // await factory.deployed();

    // console.log(`Factory deployed to: ${factory.address}`);

    const WNT: ContractFactory = await ethers.getContractFactory("WNT");

    const wnt: Contract = await WNT.deploy("Wrapped Native Token", "WNT");

    console.log(`WNT deployed to: ${wnt.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
