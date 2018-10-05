

const {
  assertRejects,
  timestamp,
  increaseTime,
  increaseTimeTo,
  padAddressToBytes32,
} = require("./utilities.js")



const ForkonomicSystem = artifacts.require('ForkonomicSystem');
const ForkonomicToken = artifacts.require('ForkonomicToken');
const Distribution = artifacts.require('Distribution');

const BigNumber = web3.BigNumber;


contract('ForkonomicERC20', function (accounts) {
  const [arbitrator0, arbitrator1, balanceHolder, approver, noFundsAccount, recipient] = accounts
  let fToken
  let branch
  let fSystem
  beforeEach(async function () {
      fToken = await ForkonomicToken.deployed()
      fSystem = await ForkonomicSystem.deployed()
      branch = await fSystem.genesisBranchHash.call();
  });

  describe('total supply', function () {
    it('returns the total amount of tokens', async function () {
      assert.equal((await fToken.totalSupply()).toNumber(), 210000000000000*4);
    });
  });

  describe('balanceOf', function () {
    describe('when the requested account has no tokens', function () {
      it('returns zero', async function () {
        assert.equal((await fToken.balanceOf(noFundsAccount, branch)).toNumber(), 0);
      });
    });

    describe('when the requested account has some tokens', function () {
      it('returns the total amount of tokens', async function () {
        assert.equal((await fToken.balanceOf(Distribution.address, branch)).toNumber(), 210000000000000);
      });
    });
  describe('transfer', function () {
    describe('when the recipient is not the zero address', function () {
      const to = recipient;

      describe('when the sender does not have enough balance', function () {
        const amount = 510000000000001;

        it('reverts', async function () {
          //assert.isTrue(amount>(await fToken.balanceOf(amount, branch)).toNumber())
          await assertRejects(fToken.transfer(to, amount, branch, { from: arbitrator0 }));
        });
      });

      describe('when the sender has enough balance', function () {
        const amount = 100;

        it('transfers the requested amount', async function () {
          const oldBalance1 = (await fToken.balanceOf(arbitrator0, branch)).toNumber()
          const oldBalance2 = (await fToken.balanceOf(recipient, branch)).toNumber()
          await fToken.transfer(recipient, amount, branch, { from: arbitrator0 });
          assert.equal((await fToken.balanceOf(arbitrator0, branch)).toNumber(), oldBalance1 -amount);
          assert.equal((await fToken.balanceOf(recipient, branch)).toNumber(), oldBalance2 +amount);
        });
      });

      describe('check the last debit window', function () {
        const amount = 100;

        it('last debit window not met', async function () {
          const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator0])
          await fSystem.createArbitratorWhitelist([arbitrator0])
          const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
          await increaseTime(waitingTime)
          const newBranchHash =  await fSystem.createBranch.call(branch, keyForArbitrators)
          await fSystem.createBranch(branch, keyForArbitrators)
          await fToken.transfer(recipient, amount, newBranchHash, { from: arbitrator0 });
          await assertRejects(fToken.transfer(recipient, amount, branch, { from: arbitrator0 }));
        });
      });
    });

  });

  });

contract('ForkonomicERC20 - transferFrom', function (accounts) {
  const [arbitrator0, arbitrator1, balanceHolder, approver, noFundsAccount, recipient] = accounts
  let fToken
  let branch
  let fSystem
  beforeEach(async function () {
      fToken = await ForkonomicToken.deployed()
      fSystem = await ForkonomicSystem.deployed()
      branch = await fSystem.genesisBranchHash.call();
  });

 
  describe('transferFrom', function () {
    describe('when the recipient is not the zero address', function () {
      const to = recipient;
      const from = arbitrator0;

      describe('when the sender does not have enough balance', function () {
        const amount = 510000000000001;

        it('reverts', async function () {
          //assert.isTrue(amount>(await fToken.balanceOf(amount, branch)).toNumber())
          
          await fToken.approve(to, amount, branch,{ from: from})
          await assertRejects(fToken.transferFrom(from, to, amount, branch, { from: from}));
        });
      });

      describe('when the sender has enough balance', function () {
        const amount = 100;

        it('transfers the requested amount', async function () {
          const oldBalance1 = (await fToken.balanceOf(from, branch)).toNumber()
          const oldBalance2 = (await fToken.balanceOf(to, branch)).toNumber()
          await fToken.approve(to, amount, branch, { from: from})
          await fToken.transferFrom(from, to, amount, branch, { from: to});

          assert.equal((await fToken.balanceOf(from, branch)).toNumber(), oldBalance1 -amount);
          assert.equal((await fToken.balanceOf(to, branch)).toNumber(), oldBalance2 +amount);
        });

        it('transfers the requested amount on a non-approved branch', async function () {
          const oldBalance1 = (await fToken.balanceOf(from, branch)).toNumber()
          const oldBalance2 = (await fToken.balanceOf(to, branch)).toNumber()
          const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator0])
          await fSystem.createArbitratorWhitelist([arbitrator0])
          const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
          await increaseTime(waitingTime)
          const newBranchHash =  await fSystem.createBranch.call(branch, keyForArbitrators)
          await fSystem.createBranch(branch, keyForArbitrators)
          await fToken.approve(to, amount, newBranchHash,{ from: from})
          await assertRejects(fToken.transferFrom(from, to, amount, branch, { from: to}));
          assert.equal((await fToken.balanceOf(from, branch)).toNumber(), oldBalance1 );
          assert.equal((await fToken.balanceOf(to, branch)).toNumber(), oldBalance2 );
        });

      });

      describe('check the last debit window', function () {
        const amount = 100;

        it('last debit window not met', async function () {
          const newBranchHash = (await fSystem.getWindowBranches(1))[0]
          await fToken.approve(to, amount, newBranchHash,{ from: from})
          await fToken.transferFrom(from, to, amount, newBranchHash, { from: to });
          branch = await fSystem.genesisBranchHash.call();
          await fToken.approve(to, amount, branch,{ from: from})
          await assertRejects(fToken.transferFrom(from, to, amount, branch, { from: to }));
        });
      });
    });

  });

  });

/*
    describe('when the recipient is the zero address', function () {
      const to = ZERO_ADDRESS;

      it('reverts', async function () {
        await assertRevert(this.token.transfer(to, 100, { from: owner }));
      });
    });
  });

  describe('approve', function () {
    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      describe('when the sender has enough balance', function () {
        const amount = 100;

        it('emits an approval event', async function () {
          const { logs } = await this.token.approve(spender, amount, { from: owner });

          expectEvent.inLogs(logs, 'Approval', {
            owner: owner,
            spender: spender,
            value: amount
          });
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.approve(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, 1, { from: owner });
          });

          it('approves the requested amount and replaces the previous one', async function () {
            await this.token.approve(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });
      });

      describe('when the sender does not have enough balance', function () {
        const amount = 101;

        it('emits an approval event', async function () {
          const { logs } = await this.token.approve(spender, amount, { from: owner });

          expectEvent.inLogs(logs, 'Approval', {
            owner: owner,
            spender: spender,
            value: amount
          });
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.approve(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, 1, { from: owner });
          });

          it('approves the requested amount and replaces the previous one', async function () {
            await this.token.approve(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });
      });
    });

    describe('when the spender is the zero address', function () {
      const amount = 100;
      const spender = ZERO_ADDRESS;

      it('reverts', async function () {
        await assertRevert(this.token.approve(spender, amount, { from: owner }));
      });
    });
  });

  describe('transfer from', function () {
    const spender = recipient;

    describe('when the recipient is not the zero address', function () {
      const to = anotherAccount;

      describe('when the spender has enough approved balance', function () {
        beforeEach(async function () {
          await this.token.approve(spender, 100, { from: owner });
        });

        describe('when the owner has enough balance', function () {
          const amount = 100;

          it('transfers the requested amount', async function () {
            await this.token.transferFrom(owner, to, amount, { from: spender });

            (await this.token.balanceOf(owner)).should.be.bignumber.equal(0);

            (await this.token.balanceOf(to)).should.be.bignumber.equal(amount);
          });

          it('decreases the spender allowance', async function () {
            await this.token.transferFrom(owner, to, amount, { from: spender });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(0);
          });

          it('emits a transfer event', async function () {
            const { logs } = await this.token.transferFrom(owner, to, amount, { from: spender });

            expectEvent.inLogs(logs, 'Transfer', {
              from: owner,
              to: to,
              value: amount
            });
          });
        });

        describe('when the owner does not have enough balance', function () {
          const amount = 101;

          it('reverts', async function () {
            await assertRevert(this.token.transferFrom(owner, to, amount, { from: spender }));
          });
        });
      });

      describe('when the spender does not have enough approved balance', function () {
        beforeEach(async function () {
          await this.token.approve(spender, 99, { from: owner });
        });

        describe('when the owner has enough balance', function () {
          const amount = 100;

          it('reverts', async function () {
            await assertRevert(this.token.transferFrom(owner, to, amount, { from: spender }));
          });
        });

        describe('when the owner does not have enough balance', function () {
          const amount = 101;

          it('reverts', async function () {
            await assertRevert(this.token.transferFrom(owner, to, amount, { from: spender }));
          });
        });
      });
    });

    describe('when the recipient is the zero address', function () {
      const amount = 100;
      const to = ZERO_ADDRESS;

      beforeEach(async function () {
        await this.token.approve(spender, amount, { from: owner });
      });

      it('reverts', async function () {
        await assertRevert(this.token.transferFrom(owner, to, amount, { from: spender }));
      });
    });
  });

  describe('decrease allowance', function () {
    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      function shouldDecreaseApproval (amount) {
        describe('when there was no approved amount before', function () {
          it('reverts', async function () {
            await assertRevert(this.token.decreaseAllowance(spender, amount, { from: owner }));
          });
        });

        describe('when the spender had an approved amount', function () {
          const approvedAmount = amount;

          beforeEach(async function () {
            ({ logs: this.logs } = await this.token.approve(spender, approvedAmount, { from: owner }));
          });

          it('emits an approval event', async function () {
            const { logs } = await this.token.decreaseAllowance(spender, approvedAmount, { from: owner });

            expectEvent.inLogs(logs, 'Approval', {
              owner: owner,
              spender: spender,
              value: 0
            });
          });

          it('decreases the spender allowance subtracting the requested amount', async function () {
            await this.token.decreaseAllowance(spender, approvedAmount - 1, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(1);
          });

          it('sets the allowance to zero when all allowance is removed', async function () {
            await this.token.decreaseAllowance(spender, approvedAmount, { from: owner });
            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(0);
          });

          it('reverts when more than the full allowance is removed', async function () {
            await assertRevert(this.token.decreaseAllowance(spender, approvedAmount + 1, { from: owner }));
          });
        });
      }

      describe('when the sender has enough balance', function () {
        const amount = 100;

        shouldDecreaseApproval(amount);
      });

      describe('when the sender does not have enough balance', function () {
        const amount = 101;

        shouldDecreaseApproval(amount);
      });
    });

    describe('when the spender is the zero address', function () {
      const amount = 100;
      const spender = ZERO_ADDRESS;

      it('reverts', async function () {
        await assertRevert(this.token.decreaseAllowance(spender, amount, { from: owner }));
      });
    });
  });

  describe('increase allowance', function () {
    const amount = 100;

    describe('when the spender is not the zero address', function () {
      const spender = recipient;

      describe('when the sender has enough balance', function () {
        it('emits an approval event', async function () {
          const { logs } = await this.token.increaseAllowance(spender, amount, { from: owner });

          expectEvent.inLogs(logs, 'Approval', {
            owner: owner,
            spender: spender,
            value: amount
          });
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, 1, { from: owner });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount + 1);
          });
        });
      });

      describe('when the sender does not have enough balance', function () {
        const amount = 101;

        it('emits an approval event', async function () {
          const { logs } = await this.token.increaseAllowance(spender, amount, { from: owner });

          expectEvent.inLogs(logs, 'Approval', {
            owner: owner,
            spender: spender,
            value: amount
          });
        });

        describe('when there was no approved amount before', function () {
          it('approves the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount);
          });
        });

        describe('when the spender had an approved amount', function () {
          beforeEach(async function () {
            await this.token.approve(spender, 1, { from: owner });
          });

          it('increases the spender allowance adding the requested amount', async function () {
            await this.token.increaseAllowance(spender, amount, { from: owner });

            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(amount + 1);
          });
        });
      });
    });

    describe('when the spender is the zero address', function () {
      const spender = ZERO_ADDRESS;

      it('reverts', async function () {
        await assertRevert(this.token.increaseAllowance(spender, amount, { from: owner }));
      });
    });
  });

  describe('_mint', function () {
    const initialSupply = new BigNumber(100);
    const amount = new BigNumber(50);

    it('rejects a null account', async function () {
      await assertRevert(this.token.mint(ZERO_ADDRESS, amount));
    });

    describe('for a non null account', function () {
      beforeEach('minting', async function () {
        const { logs } = await this.token.mint(recipient, amount);
        this.logs = logs;
      });

      it('increments totalSupply', async function () {
        const expectedSupply = initialSupply.plus(amount);
        (await this.token.totalSupply()).should.be.bignumber.equal(expectedSupply);
      });

      it('increments recipient balance', async function () {
        (await this.token.balanceOf(recipient)).should.be.bignumber.equal(amount);
      });

      it('emits Transfer event', async function () {
        const event = expectEvent.inLogs(this.logs, 'Transfer', {
          from: ZERO_ADDRESS,
          to: recipient,
        });

        event.args.value.should.be.bignumber.equal(amount);
      });
    });
  });

  describe('_burn', function () {
    const initialSupply = new BigNumber(100);

    it('rejects a null account', async function () {
      await assertRevert(this.token.burn(ZERO_ADDRESS, 1));
    });

    describe('for a non null account', function () {
      it('rejects burning more than balance', async function () {
        await assertRevert(this.token.burn(owner, initialSupply.plus(1)));
      });

      const describeBurn = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            const { logs } = await this.token.burn(owner, amount);
            this.logs = logs;
          });

          it('decrements totalSupply', async function () {
            const expectedSupply = initialSupply.minus(amount);
            (await this.token.totalSupply()).should.be.bignumber.equal(expectedSupply);
          });

          it('decrements owner balance', async function () {
            const expectedBalance = initialSupply.minus(amount);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(expectedBalance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent.inLogs(this.logs, 'Transfer', {
              from: owner,
              to: ZERO_ADDRESS,
            });

            event.args.value.should.be.bignumber.equal(amount);
          });
        });
      };

      describeBurn('for entire balance', initialSupply);
      describeBurn('for less amount than balance', initialSupply.sub(1));
    });
  });

  describe('_burnFrom', function () {
    const initialSupply = new BigNumber(100);
    const allowance = new BigNumber(70);

    const spender = anotherAccount;

    beforeEach('approving', async function () {
      await this.token.approve(spender, allowance, { from: owner });
    });

    it('rejects a null account', async function () {
      await assertRevert(this.token.burnFrom(ZERO_ADDRESS, 1));
    });

    describe('for a non null account', function () {
      it('rejects burning more than allowance', async function () {
        await assertRevert(this.token.burnFrom(owner, allowance.plus(1)));
      });

      it('rejects burning more than balance', async function () {
        await assertRevert(this.token.burnFrom(owner, initialSupply.plus(1)));
      });

      const describeBurnFrom = function (description, amount) {
        describe(description, function () {
          beforeEach('burning', async function () {
            const { logs } = await this.token.burnFrom(owner, amount, { from: spender });
            this.logs = logs;
          });

          it('decrements totalSupply', async function () {
            const expectedSupply = initialSupply.minus(amount);
            (await this.token.totalSupply()).should.be.bignumber.equal(expectedSupply);
          });

          it('decrements owner balance', async function () {
            const expectedBalance = initialSupply.minus(amount);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(expectedBalance);
          });

          it('decrements spender allowance', async function () {
            const expectedAllowance = allowance.minus(amount);
            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(expectedAllowance);
          });

          it('emits Transfer event', async function () {
            const event = expectEvent.inLogs(this.logs, 'Transfer', {
              from: owner,
              to: ZERO_ADDRESS,
            });

            event.args.value.should.be.bignumber.equal(amount);
          });
        });
      };

      describeBurnFrom('for entire allowance', allowance);
      describeBurnFrom('for less amount than allowance', allowance.sub(1));
    });
  });*/
});