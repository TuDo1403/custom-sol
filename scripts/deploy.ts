import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

async function main() {
    // const Factory: ContractFactory = await ethers.getContractFactory("UniswapV3Factory");
    // console.log({ Factory });
    // const factory: Contract = await Factory.deploy();

    // await factory.deployed();

    // console.log(`Factory deployed to: ${factory.address}`);

    // const PMT: ContractFactory = await ethers.getContractFactory("PMT");

    // const dai: Contract = await PMT.deploy("DAI", "DAI");

    // console.log(`DAI deployed to: ${dai.address}`);

    // const usdc: Contract = await PMT.deploy("Coinbase USD", "USDC");

    // console.log(`Coinbase USD deployed to: ${usdc.address}`);

    // const usdt: Contract = await PMT.deploy("Tether USD", "USDT");

    // console.log(`Tether USD deployed to: ${usdt.address}`);

    // const tbtc: Contract = await PMT.deploy("tBTC", "TBTC");

    // console.log(`tBTC deployed to: ${tbtc.address}`);

    // const wbtc: Contract = await PMT.deploy("Wrapped Bitcoin", "WBTC");

    // console.log(`Wrapped Bitcoin deployed to: ${wbtc.address}`);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
