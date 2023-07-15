import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { concat, hexlify } from "ethers/lib/utils";

describe("AssamblrV1", function () {
  
  async function deployAssamblrV1Fixture() {
    const [ signer ] = await ethers.getSigners();

    const AssamblrV1 = await ethers.getContractFactory("AssamblrV1");
    const AssamblrV1Dummy = await ethers.getContractFactory("AssamblrV1Dummy");

    const assamblrV1Dummy = await AssamblrV1Dummy.deploy("AssamblrV1", "ASSM", signer.address);
    await assamblrV1Dummy.deployed();

    const txData = hexlify(concat([
      AssamblrV1.bytecode,
      AssamblrV1Dummy.interface.encodeDeploy(["AssamblrV1", "ASSM", assamblrV1Dummy.address])
    ]))

    const tx = await signer.sendTransaction({
      data: txData,
    });

    const receipt = await tx.wait();

    return { assamblrV1: AssamblrV1Dummy.attach(receipt.contractAddress), signer };
  }
  
  describe("Metadata", function () {
    it("Should set the right name", async function () {
      const { assamblrV1 } = await loadFixture(deployAssamblrV1Fixture);
      expect(await assamblrV1.name()).to.equal("AssamblrV1");
    });
  });
});