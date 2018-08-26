# Forkonomics

Edmund Edgar
<ed@realitykeys.com>

Alexander Herrmann
<josojo@hotmail.de>

2018-08-30

### This is a work-in-progress. It is not yet complete.


## Abstract

The Forkonomics framework is a protocol for attaching value transfers to a particular bundle of facts and propositions. The fundamental pillar of this protocol is the principle of forking: Tokens can be forked into different branches. Each branch is associated with arbitrators. Arbitrators represent certain sets of facts and propositions. Smart contracts can read these arbitrators, their facts and the proposition from each branch and act upon these facts. 

Using this principle, any escalated contention about a correct decision of an arbitrator can be resolved in a very democratic manner: Every participant must make his own choice on which branch - a bundle of propositions - he would like to follow. If his subjective decision coincides with the crowd, he will follow the main branch. If his decision does not match the majority, he will be left behind on a minority branch.

The Forkonomics Fund is a fund of tokens supporting the forkonomic protocol. The bundled value of these tokens represented by a fund token will serve a currency to safely transfer value conditional to a bundle of facts.

# Introduction

Linking information from our reality into the blockchain world is a challenging problem. In general, building arbitration systems about subjective manner on the blockchain is a hard problem. Many proposed systems suffer from bribing attacks, high fees or oligarchy setups.

Subjectivocracy solves many of these challenges, as elaborated here[]. In contrast to many other proposals, subjectivocracy does no longer tries to find a unique answer to a question but incorporates different answers or judgments on different branches of the system. The system forks regularly and writes different subjective opinions about a fact into the different branches. Users have to recognize these different answers and they have to subjectively choose their correct branch. As the platform for finding the truth is no longer the smart contracts per se, but the various social platform, any manipulation or bribing attack is hard and involves manipulating the public opinion.

As pure subjectivocracy might end up with many, many forks and a hassle for the users to choose the correct fork, this concept is improved via two mechanisms: Arbitrators selection and escalation betting.
Instead of deciding on pure facts, branches only represent a list of reputable arbitrators. The facts and the propositions of the branch are only indirectly represented via the arbitrator's propositions. If an arbitrator makes a disputable answer, then anyone can just create a new branch delisting this arbitrator.
Making arbitrators decide on each question is quite inefficient. Therefore, an escalation game, where people can bet on the decision of the arbitrator is in place. 
This system, the subjectivocray advanced by escalation betting and arbitrator selection is called a forkonomic system.

One fundamental building block of a subjectivocracy system is that there needs to be token, which can easily be forked into the different branches. It is crucial that this token has the best possible value proposition, as payments of the system need to be settled within this token. Using an Exchange-Traded-Fund(ETF) of tokens, which support the forkonomic protocol is the best option for this subjectivocracy token, as ETF's have the best value proposition over the long term.

## Key Building Blocks

### Realit.io - asking questions

Realit.io has built a platform, which increases the efficiency of arbitration. On this platform, questions can be asked for an arbitrary arbitrator. When the question can be resolved, the arbitrator does not need to take action. Peers from the platform can provide the question's answer and a bond. If someones see that the wrong an incorrect answer was provided, then they can correct the answer, but they need to double the bond. This game escalates pretty quickly, as in each challenge the bond needs to be escalated. Only if the bonding reaches a certain threshold, it gets profitable to pay the arbitrator and arbitrate between the different bonded answers.

Any question entering the forkonomic system should get asked on Realit.io with an arbitrator from a branch. 
Now, there are 3 outcomes:
1. The question gets answered without an escalation game. 
This should be the usual case. Here, the correct answer is provided from the beginning. The smart contracts of the forkonomic system can easily read the correct answer from realit.io.
2. The question gets escalated to the arbitrator.
Now, the answer needs to be provided by the arbitrator. In most cases, the arbitrator will tell the truth and the dishonest answer provider gets slashed and loses his bond. The smart contracts of the forkonomic system can easily read the correct answer from realit.io. 
3. The question gets escalated to the arbitrator and the arbitrator is dishonest.
Such a situation should create a big social outcry. People would get aware of this malicious behavior of the arbitrator and they would start to create new branches delisting the arbitrator from the system. The smart contracts of the forkonomic system will only read the answer from realit.io on branches, where the arbitrator is still listed. For the other branches, the question needs to be resubmitted to realit.io with another valid arbitrator. Then the escalation game starts again and the process repeats itself.

While realit.io is very efficient and effective, there might be the need for different escalation games depending on the application. If there are at some point several platforms, the forkonomic dapps could use the platform fitting the best to their needs.

### Forkonomic-protocol - doing arbitration 

The forkonomic-protocol does the ultimate arbitration of the arbitrator list. As pointed out before, the forkonomic system allows anyone to fork the system and introduce a new branch with a new list of arbitrators. Whenever someone feels that the arbitrator list should be altered, may it due to an incorrect behavior of the arbitrator or due to an addition of further arbitrators, a new branch can be added on a smart contract level (cf. ForkonomicSystem.sol). The addition of the new branch is basically free, but getting people adapting to it is the real cost. 
A new branch will only get adaption, if it benefits the Forknomic-system, other branches will be left behind quickly. This benefit could be the elimination of bad arbitrators or a well-discussed addition of new arbitrators. This is a reinforcement system, where bad decision won't be adapted, as they hurt the system and good decision will be adapted, as they benefit the system. Others would describe this system as a token curated list of a good decision.
The beauty of such a system is that the logic for choosing a branch is not determined in smart contracts. The logic is determined on a social basis. This is powerful, as no constant logic has the capability to fit all new conditions. However, the social decision logic is flexible enough to make the right decision at the right point of time and still the system is robust enough that these decisions can be coordinated well.

In this system, any interaction with a smart contract always happens on a specified branch chosen by the user. Usually, there should be only one main branched used by all participants. Only in case of a controversy, there might be several viable branches. In this situation, the user has to options:
1. user might evaluate the controversy and chooses a specific branch for all further interaction.
2. user might make his transaction on several branches in order to ensure that the transaction is happening on the branch, which will get the best adaption later.  

As the second option comes with an additional gas cost, the users will in most situations choose a specific branch, the branch they expect to become the next main branch. Of course, they will not choose any malicious branch, as this branch would not get any increased adaption, as long as people can identify the malicious arbitrators.

Dapp building on top of the forkonomic system will be built in such a manner that they can easily deal with all the different branches created. If these dapps have their own token, they can also make this token compatible with the forkonomic-token standard. This standard is quite the same as the ERC20 token standard, but with the difference that tokens always need to be transferred on a specified branch (cf. ForkonomicToken.sol). These branches need to be in coherence with the branch system of the whole forkonomic system.

### Forkonomics-ETF

If there are any successful dapps using the forkonomic-token protocol, then these tokens can be bundled in a forkonomic-Exchange-Traded-Fund (forkonomic-ETF). Of course, the forkonomic-ETF would have its own token, tracking the ETFs value. This token would for sure also follow the forkonomic protocol. Forkonomic tokens can be added to the ForkonomicETF by the following process:
1. Anyone can make a proposal to add or remove tokens to the fund
2. The fund will take the proposal and make a question to realit.io and a current arbitrator, whether this proposal should be accepted.
3. Realit.io will answer this question
4. The funds smart-contract will read the answer from realit.io. If the arbitrator is still white-listed on this particular branch and the answer from realit.io is yes, then we will add the token to the forkonomics fund. The token provider will be compensated with forkonomic-tokens.

This process allows a fund management based on an arbitrator managing the fund. However, even when the arbitrator becomes a bad guy, we still have the forkonomics back-up to branch the arbitrator off.

The Forkonomics-ETF plays a central role in the Forkonomics ecosystem. The forkonomic system is a platform for value transfers conditional to propositions or arbitrator decisions. As mentioned before, in order to use subjectivocracy all payments need to be performed with a forkable token as collateral. Probably, the Forkonomics-ETF token is the preferred collateral in the ecosystem, as it backed by stocks with relatively well spread risks.

###	RealityToken - Bootstrapping the system

...

### Forknomonics - Cooperations

We can imagine a wide spread of application of this forkonomics system. Here, we wanna list the most obvious dapps, which can be built

#### Examples:

1. Insurances: Hurricane parametric insurance, Flood parametric insurance, fire insurances, car insurances, employment insurances. The intelligent insurance policy selection process of insurance DAO's in order to cover policies with well-spread risk ( this would also allow fraction default coverage).
2. Derivative Markets: All kind of markets for trading derivatives in a decentralized fashing can be built. These derivatives could be once tokenized and then later freely be traded on plasma exchanges
3. Gambling applications
4. Arbitration between contract partners
5. Arbitration platform for gitcoin like projects

### Timeline:

### Current code:

Take a look at the repo: ... for gnosis scalar markets based on forkonomics.
