import { ethers } from "hardhat";

async function main() {
  const [ signer ] = await ethers.getSigners();
  const contract = await ethers.getContractFactory("AssamblrV1Dummy");

  // Just to get the contract interface
  const contractInstance = contract.attach(signer.address);

  const sigs = Object.keys(contractInstance.interface.functions);

  const sigHashes = sigs.reduce((acc, sig) => {
    acc[sig] = contract.interface.getSighash(sig);
    return acc;
  }, {} as Record<string, string>);

  console.log(JSON.stringify(sigHashes, null, 2));

  const txData = contractInstance.interface.encodeFunctionData("setApprovalForAll", [signer.address, true]);
  console.log(txData);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

