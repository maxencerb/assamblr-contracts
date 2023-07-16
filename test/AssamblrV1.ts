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
      await expect(assamblrV1.mint(signer.address)).to.emit(assamblrV1, "Transfer").withArgs(ethers.constants.AddressZero, signer.address, 1);

      const balanceSigner = await assamblrV1.balanceOf(signer.address);
      const balanceOther = await assamblrV1.balanceOf(other.address);

      expect(balanceSigner).to.equal(1);
      expect(balanceOther).to.equal(0);

      const owner = await assamblrV1.ownerOf(1);
      expect(owner).to.equal(signer.address);
      await expect(assamblrV1.connect(signer).transferFrom(signer.address, other.address, 1)).to.emit(assamblrV1, "Transfer").withArgs(signer.address, other.address, 1);

      const newBalanceSigner = await assamblrV1.balanceOf(signer.address);
      const newBalanceOther = await assamblrV1.balanceOf(other.address);
      const newOwner = await assamblrV1.ownerOf(1);
      expect(newBalanceSigner).to.equal(0);
      expect(newBalanceOther).to.equal(1);

      expect(newOwner).to.equal(other.address);

      await expect(assamblrV1.connect(signer).transferFrom(signer.address, other.address, 1)).to.be.revertedWithoutReason();
    });

    it("Should work with approvals", async function () {
      const { assamblrV1, signer, other } = await loadFixture(deployAssamblrV1Fixture);
      await expect(assamblrV1.mint(signer.address)).to.emit(assamblrV1, "Transfer").withArgs(ethers.constants.AddressZero, signer.address, 1);
      await expect(assamblrV1.mint(signer.address)).to.emit(assamblrV1, "Transfer").withArgs(ethers.constants.AddressZero, signer.address, 2);

      await assamblrV1.connect(signer).approve(other.address, 1);

      const _spender = await assamblrV1.getApproved(1);
      expect(_spender).to.equal(other.address);
      const _spender2 = await assamblrV1.getApproved(2);
      expect(_spender2).to.equal(ethers.constants.AddressZero);

      await expect(assamblrV1.connect(other).transferFrom(signer.address, other.address, 2)).to.be.revertedWithoutReason();
      await assamblrV1.connect(other).transferFrom(signer.address, other.address, 1);
      

      const newOwner = await assamblrV1.ownerOf(1);
      expect(newOwner).to.equal(other.address);

      const _newSpender = await assamblrV1.getApproved(1);
      expect(_newSpender).to.equal(ethers.constants.AddressZero);
    });

    it("Should work with global approvals", async function () {
      const { assamblrV1, signer, other } = await loadFixture(deployAssamblrV1Fixture);
      await assamblrV1.mint(signer.address);
      await assamblrV1.mint(signer.address);
      await assamblrV1.mint(signer.address);

      const _spender = await assamblrV1.isApprovedForAll(signer.address, other.address);
      expect(_spender).to.equal(false);

      await assamblrV1.connect(signer).setApprovalForAll(other.address, true);

      const _spenderNew = await assamblrV1.isApprovedForAll(signer.address, other.address);
      expect(_spenderNew).to.equal(true);

      await assamblrV1.connect(other).transferFrom(signer.address, other.address, 1);
      await assamblrV1.connect(other).transferFrom(signer.address, other.address, 2);

      const newOwner = await assamblrV1.ownerOf(1);
      expect(newOwner).to.equal(other.address);
      const newOwner2 = await assamblrV1.ownerOf(2);
      expect(newOwner2).to.equal(other.address);

      await assamblrV1.connect(signer).setApprovalForAll(other.address, false);

      const _spenderNew2 = await assamblrV1.isApprovedForAll(signer.address, other.address);
      expect(_spenderNew2).to.equal(false);

      await expect(assamblrV1.connect(other).transferFrom(signer.address, other.address, 3)).to.be.revertedWithoutReason();
    });
  });
});