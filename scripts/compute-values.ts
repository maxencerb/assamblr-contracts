import { ethers } from "hardhat";

async function main() {
  const [ signer ] = await ethers.getSigners();
  const contract = await ethers.getContractFactory("AssamblrV1Dummy");
  const contractInstance = await contract.deploy("AssamblrV1", "ASSM", signer.address);

  const sigs = Object.keys(contractInstance.interface.functions);

  const sigHashes = sigs.reduce((acc, sig) => {
    acc[sig] = contract.interface.getSighash(sig);
    return acc;
  }, {} as Record<string, string>);

  console.log(JSON.stringify(sigHashes, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

