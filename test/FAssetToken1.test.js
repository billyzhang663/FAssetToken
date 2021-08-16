const { expect } = require("chai");
const { blockNumber } = require('./utils/Ethereum');
const bigNum = num => (num + '0'.repeat(18))

describe("FAssetToken1", function () {
  let FAssetToken;
  let hardhatToken;
  let owner;
  let bob;
  let lucy;
  let ed;

  before(async function () {
    FAssetToken = await ethers.getContractFactory("FAssetToken1");
    [owner, bob, lucy, ed] = await ethers.getSigners();
    hardhatToken = await FAssetToken.deploy("FAssetToken1", "FAT");
  });

  it("Should mint tokens to users", async () => {
    try {
      expect(await hardhatToken.connect(owner).mint(bob.address, 20, { value: bigNum(1) }));
      expect(await hardhatToken.connect(owner).mint(lucy.address, 10, { value: bigNum(1) }));
    } catch (err) {
      console.log('Error Message', err.message);
    }
  });

  it ("Should delegate voting power from bob to luch and Ed", async () => {
    try {
      expect((await hardhatToken.balanceOf(bob.address)).toString()).to.equal('20');
      expect((await hardhatToken.balanceOf(lucy.address)).toString()).to.equal('10');
      expect((await hardhatToken.balanceFromDelegationOfAt(bob.address)).toString()).to.equal('100');

      expect((await hardhatToken.connect(bob).delegate(lucy.address, 50)));
      expect((await hardhatToken.connect(bob).delegate(ed.address, 75))).to.be.revertedWith("asdfsfd");

      let bn0 = await blockNumber()
      expect((await hardhatToken.votePowerOfAt(lucy.address, bn0++)).toString()).to.equal('20');
      expect((await hardhatToken.votePowerOfAt(ed.address, bn0++)).toString()).to.equal('5');

      expect((await hardhatToken.connect(owner).mint(bob.address, 16)));

      let bn1 = await blockNumber()
      expect((await hardhatToken.votePowerOfAt(lucy.address, bn1++)).toString()).to.equal('28');
      expect((await hardhatToken.votePowerOfAt(bob.address, bn1++)).toString()).to.equal('9');
      expect((await hardhatToken.votePowerOfAt(ed.address, bn1++)).toString()).to.equal('9');

      expect((await hardhatToken.connect(lucy).delegate(ed.address, 100)));

      let bn2 = await blockNumber()
      expect((await hardhatToken.votePowerOfAt(lucy.address, bn2++)).toString()).to.equal('18');
      expect((await hardhatToken.votePowerOfAt(ed.address, bn2++)).toString()).to.equal('19');
    } catch(err) {
      console.log('Error Message', err.message);
    }
  });
});
