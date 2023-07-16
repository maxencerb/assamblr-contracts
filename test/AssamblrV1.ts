import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { concat, hexlify } from "ethers/lib/utils";

describe("AssamblrV1", function () {
  
  async function deployAssamblrV1Fixture() {
    const [ signer, other ] = await ethers.getSigners();

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

    return { assamblrV1: AssamblrV1Dummy.attach(receipt.contractAddress), signer, other };
  }
  
  describe("Metadata", function () {
    it("Should set the right name", async function () {
      const { assamblrV1 } = await loadFixture(deployAssamblrV1Fixture);
      expect(await assamblrV1.name()).to.equal("AssamblrV1");
    });

    it("Should set the right symbol", async function () {
      const { assamblrV1 } = await loadFixture(deployAssamblrV1Fixture);
      expect(await assamblrV1.symbol()).to.equal("ASSM");
    });

    it("Should set the right owner", async function () {
      const { assamblrV1, signer, other } = await loadFixture(deployAssamblrV1Fixture);
      expect(await assamblrV1.owner()).to.equal(signer.address);
      await assamblrV1.transferOwnership(other.address);
      expect(await assamblrV1.owner()).to.equal(other.address);

      await expect(assamblrV1.connect(signer).transferOwnership(other.address)).to.be.revertedWithoutReason();

      await assamblrV1.connect(other).transferOwnership(signer.address);
      expect(await assamblrV1.owner()).to.equal(signer.address);

      await assamblrV1.renounceOwnership();
      expect(await assamblrV1.owner()).to.equal(ethers.constants.AddressZero);

      await expect(assamblrV1.connect(other).renounceOwnership()).to.be.revertedWithoutReason();
    });
  });

  describe("Actions", function () {
    it("Should mint tokens", async function () {
      const { assamblrV1, signer, other } = await loadFixture(deployAssamblrV1Fixture);
      const balance = await assamblrV1.balanceOf(other.address);
      expect(balance).to.equal(0);
      await assamblrV1.connect(signer).mint(other.address);
      const newBalance = await assamblrV1.balanceOf(other.address);
      expect(newBalance).to.equal(1);
    });

    it("Should transfer tokens", async function () {
      const { assamblrV1, signer, other } = await loadFixture(deployAssamblrV1Fixture);
      await assamblrV1.mint(signer.address);

      const balanceSigner = await assamblrV1.balanceOf(signer.address);
      const balanceOther = await assamblrV1.balanceOf(other.address);

      const owner = await assamblrV1.ownerOf(1);
      expect(owner).to.equal(signer.address);
      await assamblrV1.connect(signer).transferFrom(signer.address, other.address, 1);

      const newBalanceSigner = await assamblrV1.balanceOf(signer.address);
      const newBalanceOther = await assamblrV1.balanceOf(other.address);
      const newOwner = await assamblrV1.ownerOf(1);
      expect(newBalanceSigner).to.equal(0);
      expect(newBalanceOther).to.equal(1);

      expect(newOwner).to.equal(other.address);

      await expect(assamblrV1.connect(signer).transferFrom(signer.address, other.address, 1)).to.be.revertedWithoutReason();
    });
  });
});