
const {
  assertRejects,
  timestamp,
  increaseTime,
  increaseTimeTo,
  padAddressToBytes32,
} = require("./utilities.js")
const { wait } = require('@digix/tempo')(web3)



const ForkonomicSystem = artifacts.require('ForkonomicSystem');
const RealityCheck = artifacts.require('RealityCheck');
const ForkonomicToken = artifacts.require('ForkonomicToken');
const Distribution = artifacts.require('Distribution');

const BigNumber = web3.BigNumber;
const reward  = 1000000000000;

contract('Distribution- initialization', function (accounts) {
  const [arbitrator0, arbitrator1, balanceHolder, futureBalanceHolder] = accounts

  let distribution
  before(async function () {
 	  	distribution = await Distribution.deployed()

  });

  it('Injection of rewards is possible', async () => {

  	await distribution.injectReward([futureBalanceHolder],[reward])
  	assert.equal((await distribution.balances(futureBalanceHolder)).toNumber(), reward)

  })

  it('Reality Parameters can be set', async () => {
  	await distribution.setRealityVariables(ForkonomicToken.address, RealityCheck.address, ForkonomicSystem.address)
  	assert.equal((await distribution.fSystem()), ForkonomicSystem.address)

  })

  it('other addresses than the owner can not finalize', async () => {
  	await  assertRejects(distribution.finalize({from: balanceHolder}))
  })

  it('no more settings work after the finalization', async () => {
  	await distribution.finalize();
  	await assertRejects(distribution.setRealityVariables(ForkonomicToken.address, RealityCheck.address, ForkonomicSystem.address))
	await assertRejects(distribution.injectReward([futureBalanceHolder],[reward]))
  })
 })

contract('Distribution - interaction with RealityCheck', function (accounts) {
  const [arbitrator0, arbitrator1, balanceHolder, futureBalanceHolder] = accounts

  let distribution
  let realityCheck 
  let branch
  let questionId
  let fSystem
  let newBranchHash
  let fToken 
  before(async function () {
  	
  });

  it('distribution setup', async () => {
  	//setting up the distribution token
  	distribution = await Distribution.deployed()
	await distribution.setRealityVariables(ForkonomicToken.address, RealityCheck.address, ForkonomicSystem.address)
  	await distribution.injectReward([futureBalanceHolder],[reward])
  	await distribution.finalize();
  	questionId = await distribution.askRealityCheck.call(arbitrator0)
  	await distribution.askRealityCheck(arbitrator0)

  })



  it('setup realityCheck', async () => {
  	//supply answer in realitycheck
    realityCheck = await RealityCheck.deployed()
    const openingTs = await distribution.openingTs();
  	await increaseTimeTo(openingTs)
  	await realityCheck.submitAnswer(questionId, padAddressToBytes32(futureBalanceHolder), 200000, {value: 100000000})
  	const timeout = (await realityCheck.getQuestionFinalizationTs(questionId)).toNumber()
  	await increaseTime(timeout+1)
  })
  
  it('Creating new branches', async () => {
    fSystem = await ForkonomicSystem.deployed();
    const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator0])
    await fSystem.createArbitratorWhitelist([arbitrator0])
    const genesis_branch = await fSystem.genesisBranchHash();
    const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
    await increaseTime(waitingTime)
    newBranchHash =  await fSystem.createBranch.call(genesis_branch, keyForArbitrators)
  await fSystem.createBranch(genesis_branch, keyForArbitrators)
  })

  it('check that the future balance holder will receive their funds', async ()=>{
  	  fToken = await ForkonomicToken.deployed()
  	  const prevBalance = (await fToken.balanceOf(futureBalanceHolder, newBranchHash)).toNumber();
  	  await distribution.delayedDistributionLeftOverTokens(newBranchHash, questionId, arbitrator0)
  	  const newBalance = (await fToken.balanceOf(futureBalanceHolder, newBranchHash)).toNumber();
  	  assert.equal(prevBalance + 210000000000000, newBalance, "balances are not update correctly")
  })

 })