import { ethers } from "hardhat";

async function main() {
  const [ signer ] = await ethers.getSigners();
  const contract = await ethers.getContractFactory("AssamblrDummy");

  // Just to get the contract interface
  const contractInstance = contract.attach(signer.address);
  // const contractInstance = await contract.deploy("AssamblrV1", "ASSM", signer.address);
  // await contractInstance.deployed();

  const sigs = Object.keys(contractInstance.interface.functions);

  const sigHashes = sigs.reduce((acc, sig) => {
    acc[sig] = contract.interface.getSighash(sig);
    return acc;
  }, {} as Record<string, string>);

  console.log(JSON.stringify(sigHashes, null, 2));

  const events = Object.keys(contractInstance.interface.events);
  const eventHashes = events.reduce((acc, event) => {
    acc[event] = contract.interface.getEventTopic(event);
    return acc;
  }, {} as Record<string, string>);
  console.log(JSON.stringify(eventHashes, null, 2));

  // storage for baseURI
  const baseURIStorage = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("storage.erc721.baseURI"));
  console.log("baseURIStorage", baseURIStorage);

  const symbols = "0123456789abcdef";
  const symbolsUTF8 = Buffer.from(ethers.utils.toUtf8Bytes(symbols)).toString("hex");
  console.log("symbolsUTF8", symbolsUTF8);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

