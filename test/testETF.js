const {
  assertRejects,
  timestamp,
  increaseTime,
  increaseTimeTo,
  padAddressToBytes32,
} = require("./utilities.js")
const { wait } = require('@digix/tempo')(web3)


const ForkonomicSystem = artifacts.require('ForkonomicSystem');
const Realitio = artifacts.require('Realitio');
const ForkonomicToken = artifacts.require('ForkonomicToken');
const ForkonomicETTF = artifacts.require('ForkonomicETTF');

const BigNumber = web3.BigNumber;
const reward  = 1000000000000;

contract('ForkonomicETTF- initialization', function (accounts) {
  const [tester, arbitrator1, balanceHolder, futureBalanceHolder] = accounts
  let fToken
  let branch
  let branchOriginal
  let fSystem
  let newBranchHash
  let initialBalance 
  let questionId
  let realityCheck
  let balanceProposer
  let balanceChange= 5000
  let compensation = -5000
  beforeEach(async function () {
      fToken = await ForkonomicToken.deployed()
      fSystem = await ForkonomicSystem.deployed()
      branch = await fSystem.genesisBranchHash.call()
      fETTF = await ForkonomicETTF.deployed()
      realityCheck = await Realitio.deployed()
  });

  it('propose new investment for ETTF', async () => {
    initialBalance = (await fToken.balanceOf(tester, branch)).toNumber()
    const nullHash = await fSystem.NULL_HASH();
    proposalHash = await fETTF.calcDealBytes.call(branch, fToken.address, balanceChange, compensation, {from: tester}) 
    await fToken.approveBox(fETTF.address, balanceChange, branch, nullHash, proposalHash, {from: tester})
    const minBond = (await fETTF.minQuestionFunding()).toNumber();
    balanceProposer = (await fToken.balanceOf(tester, branch)).toNumber()
    questionId = await fETTF.proposeInvestment.call(branch, fToken.address, balanceChange, compensation, arbitrator1, nullHash, {from: tester, value: minBond}) 
	await fETTF.proposeInvestment(branch, fToken.address, balanceChange, compensation, arbitrator1, nullHash, {from: tester, value: minBond})
    branchOriginal = branch
  })

  it('decline the investment proposal by realityCheck', async () => {
    const openingTs = await fETTF.openingTs.call();
  	await increaseTimeTo(openingTs.toNumber())
  	const nullHash = await fSystem.NULL_HASH.call();
  	const minBond = (await fETTF.minQuestionFunding.call()).toNumber();
  	await realityCheck.submitAnswer(questionId, nullHash, minBond, {value: minBond})
  	const timeout = (await realityCheck.getFinalizeTS(questionId)).toNumber()
  	await increaseTimeTo(timeout+1)
  })

  it('append new branches', async () => {
    const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator1])
    await fSystem.createArbitratorWhitelist([arbitrator1])

    const nrOfBranches = (await timestamp() - await fSystem.genesisWindowTimestamp.call())/(await fSystem.WINDOWTIMESPAN.call()).toNumber()
    for (var i = 1; i < nrOfBranches; i++) {
      newBranchHash =  await fSystem.createBranch.call(branch, keyForArbitrators)
      await fSystem.createBranch(branch, keyForArbitrators)
      branch = newBranchHash
    }
    const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
    await increaseTime(waitingTime)
    newBranchHash =  await fSystem.createBranch.call(branch, keyForArbitrators)
    await fSystem.createBranch(branch, keyForArbitrators)
})
  it('proposer needs to get his funds back', async () => {
  	   const nullHash = await fSystem.NULL_HASH();
  	await fETTF.executeInvestmentRequest(questionId, newBranchHash, branch,fToken.address, balanceChange, compensation, arbitrator1, nullHash)
  	assert.equal((await fToken.balanceOf(tester, newBranchHash)).toNumber(), initialBalance)
  })

  it('proposer needs to get his funds back', async () => {
  	const nullHash = await fSystem.NULL_HASH()
  	await assertRejects(fETTF.executeInvestmentRequest(questionId, newBranchHash, branchOriginal, fToken.address, balanceChange, compensation, arbitrator1, nullHash))
  	assert.equal((await fToken.balanceOf(tester, newBranchHash)).toNumber(), initialBalance)
  })

 })
