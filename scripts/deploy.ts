import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const Assamblr = await ethers.getContractFactory("Assamblr");
  const AssamblrDummy = await ethers.getContractFactory("AssamblrDummy");

  console.log("Deploying AssamblrDummy...");
  const assamblrDummy = await AssamblrDummy.deploy("Assamblr", "ASBLR", deployer.address);
  console.log("AssamblrDummy deployed to:", assamblrDummy.address);

  console.log("Deploying Assamblr...");
  const assamblr = await Assamblr.deploy("Assamblr", "ASBLR", assamblrDummy.address);
  console.log("Assamblr deployed to:", assamblr.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// Deploying contracts with the account: 0x5D1E6Fe9df6b8a68B30F06Bd3f8a997cf59e1C95
// Deploying AssamblrDummy...
// AssamblrDummy deployed to: 0x7a01AF8135bDE8D903C86AE540107b4AA6CC1Cb7
// Deploying Assamblr...
// Assamblr deployed to: 0x38870BF40e6B149Acd01305EBAe044D728fF7e7e
