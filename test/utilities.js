    let Web3Utils = require('web3-utils');

  /*
   How to avoid using try/catch blocks with promises' that could fail using async/await
   - https://blog.grossman.io/how-to-write-async-await-without-try-catch-blocks-in-javascript/
   */

  const assertRejects = async (q, msg) => {
    let res, catchFlag = false
    try {
      res = await q
      // checks if there was a Log event and its argument l contains string "R<number>"
      catchFlag = res.logs && !!res.logs.find(log => log.event === "Log" && /\bR(\d+\.?)+/.test(log.args.l))
    } catch (e) {
      catchFlag = true
    } finally {
      if (!catchFlag) {
        assert.fail(res, null, msg)
      }
    }
  }

  const catchError = function(promise) {
    return promise.then(result => [null, result])
      .catch(err => [err])
  }

  // Wait for n blocks to pass
  const waitForNBlocks = async function(numBlocks, authority) {
    for (let i = 0; i < numBlocks; i++) {
      await web3.eth.sendTransaction({from: authority, "to": authority, value: 100})
    }
  }

  const timestamp = async (block = 'latest') =>  web3.eth.getBlock(block).then(t=>Web3Utils.hexToNumber(t.timestamp))

  const jsonrpc = '2.0'
  const id = 0
  const send = (method, params = []) =>
    web3.currentProvider.send({ id, jsonrpc, method, params })

  const timeTravel = async seconds => {
    await send('evm_increaseTime', [seconds])
    await send('evm_mine')
  }

  const timeTravel2 =  async (time) =>{
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
    jsonrpc: '2.0', 
    method: 'evm_increaseTime', 
    params: [time], 
    id: new Date().getSeconds()
  }, (err, resp) => {
    if (!err) {
      web3.currentProvider.send({
      jsonrpc: '2.0', 
      method: 'evm_mine', 
      params: [], 
      id: new Date().getSeconds()
    })
    }
  })
  })
  }


  // Increases ganache time by the passed duration in seconds
  function increaseTime (duration) {
    const id = Date.now();

    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration],
        id: id,
      }, err1 => {
        if (err1) return reject(err1);

        web3.currentProvider.send({
          jsonrpc: '2.0',
          method: 'evm_mine',
          params: [],
          id: id + 1,
        }, (err2, res) => {
          return err2 ? reject(err2) : resolve(res);
        });
      });
    });
  }

  /**
   * Beware that due to the need of calling two separate ganache methods and rpc calls overhead
   * it's hard to increase time precisely to a target point so design your test to tolerate
   * small fluctuations from time to time.
   *
   * @param target time in seconds
   */
  async function increaseTimeTo (target) {
    const now = (await timestamp());

    if (target < now) { 
      console.log(`Cannot increase current time(${now}) to a moment in the past(${target})`);
      return increaseTime(0);
    }
    const diff = target - now;
    return increaseTime(diff);
  }

  function padAddressToBytes32(a){
    const b = '000000000000000000000000'
    const padded = [a.slice(0, 2), b, a.slice(2)].join('');
    return padded;  
  }
  const duration = {
    seconds: function (val) { return val; },
    minutes: function (val) { return val * this.seconds(60); },
    hours: function (val) { return val * this.minutes(60); },
    days: function (val) { return val * this.hours(24); },
    weeks: function (val) { return val * this.days(7); },
    years: function (val) { return val * this.days(365); },
  };

  module.exports = {
    increaseTime,
    increaseTimeTo,
    duration,
  };

  module.exports = {
    assertRejects,
    timestamp,
    timeTravel,
    timeTravel2,
    waitForNBlocks,
    increaseTime,
    increaseTimeTo,
    padAddressToBytes32,
  }