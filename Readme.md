Forkonomics
=======


Collection of smart contracts for the Forkonomic-ecosystem.


Introduction to Forkonomics:
-------------


The Forkonomics framework is a protocol for attaching value transfers to a particular bundle of facts and propositions. The fundamental pillar of this protocol is the principle of forking: Tokens can be forked into different branches. Each branch is associated with a set of arbitrators. Arbitrators represent certain sets of facts and propositions. Smart contracts can read these arbitrators, their facts and the proposition from each branch and act upon these facts.

The goverance in forkonomics always follows the same pattern. Usually the arbitration or governmental decision are made by preselected arbitrators. This is very efficient, as these arbitrators do quick decision and they will be bonded to make valuable decisions. 
In case the community finds these arbitrators decision questionable, there will be a much slower and involving decision process. The process of forking the system and deselcting bad arbitrators.  

Using this principle, any escalated contention about a correct decision of an arbitrator will be resolved in a very liberal manner: Every participant must make his own choice on which branch - a bundle of propositions - he would like to follow. If his subjective decision coincides with the crowd, he will follow the main branch. If his decision does not match the majority, he will be left behind on a minority branch. Minority branches will never be stopped, these communities are free to grow up another new economy with different arbitrators.

This subjectivocracy approach is combined with economic abstraction. The Forkonomics Fund is a fund of tokens supporting the forkonomic protocol and govered by the arbitrators of the system. The bundled value of these tokens represented by this exchange traded token fund (ETTF) will serve a currency to safely transfer value conditional to a bundle of facts. 

Please see the attached Forkonomics.md [Frokonomics md](https://github.com/josojo/subjectivocracy/Forkonomics.md) for the long version.


Audit
-----
### Audit Report:

[To be linked]()


Install
-------
### Install requirements with npm:

Install truffle 5.0 globally. Then:

```bash
npm install
```

Testing
-------
### Start the TestRPC with bigger funding than usual, which is required for the tests:

```bash
truffle test
```
Please install at least node version >=7 for `async/await` for a correct execution

### Run all tests 

```bash
truffle test 
```

Compile and Deploy
------------------
These commands apply to the RPC provider running on port 8545. You may want to have TestRPC running in the background. They are really wrappers around the [corresponding Truffle commands](http://truffleframework.com/docs/advanced/commands).

### Compile all contracts to obtain ABI and bytecode:

```bash
truffle compile --all
```

### Migrate all contracts:

```bash
truffle migrate --network NETWORK-NAME
```



Contributors
------------
- Edmund Edgar ([edmundedgar](https://github.com/edmundedgar))
- Alexander ([josojo](https://github.com/josojo))
