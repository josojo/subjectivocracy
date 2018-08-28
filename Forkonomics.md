# Forkonomics

Edmund Edgar
<ed@realitykeys.com>

Alexander Herrmann
<josojo@hotmail.de>

2018-08-30

### This is a work-in-progress. It is not yet complete.


## Abstract

The Forkonomics framework is a protocol for attaching value transfers to a particular bundle of facts and propositions. The fundamental pillar of this protocol is the principle of forking: Tokens can be forked into different branches. Each branch is associated with a set of arbitrators. Arbitrators represent certain sets of facts and propositions. Smart contracts can read these arbitrators, their facts and the proposition from each branch and act upon these facts.

The goverance in forkonomics always follows the same pattern. Usually the arbitration or governmental decision are made by preselected arbitrators. This is very efficient, as these arbitrators do quick decision and they will be bonded to make valuable decisions. 
In case the community is not okay with an arbitrators decision, there will be a much slower and involving decision process. The process of forking the system and deselcting bad arbitrators.  

Using this principle, any escalated contention about a correct decision of an arbitrator will be resolved in a very democratic manner: Every participant must make his own choice on which branch - a bundle of propositions - he would like to follow. If his subjective decision coincides with the crowd, he will follow the main branch. If his decision does not match the majority, he will be left behind on a minority branch.

The Forkonomics Fund is a fund of tokens supporting the forkonomic protocol. The bundled value of these tokens represented by a fund token will serve a currency to safely transfer value conditional to a bundle of facts.

# Introduction

Linking information from our reality into the blockchain world is a challenging problem. In general, building arbitration systems about subjective manners on the blockchain is a hard problem. Many proposed systems suffer from bribing attacks, high fees or oligarchy setups.

Subjectivocracy solves many of these challenges, as elaborated [here](https://blog.ethereum.org/2015/02/14/subjectivity-exploitability-tradeoff/). In contrast to many other proposals, subjectivocracy does no longer tries to find a unique answer to a question but incorporates different answers or judgments on different branches of the system. The system forks regularly and writes different subjective opinions about a fact into the different branches. Users have to recognize these different answers and they have to subjectively choose their correct branch. As the platform for finding the truth is no longer the smart contracts per se, but the various social platform, any manipulation is hard and must involve manipulating the public opinion.

As pure subjectivocracy might end up with many forks and a hassle for the users to choose the correct fork, this concept is improved via two mechanisms: Arbitrators selection and escalation betting.
Instead of deciding on pure facts, branches only represent a list of reputable arbitrators. The facts and the propositions of the branch are only indirectly represented via the arbitrator's propositions. If an arbitrator makes a disputable answer, then anyone can just create a new branch delisting this arbitrator.
Making arbitrators decide on each question is quite inefficient. Therefore, an escalation game, where people can bet on the decision of the arbitrator, is in place. 
This system, the subjectivocray advanced by escalation betting and arbitrator selection is called a forkonomic system.

One fundamental building block of a subjectivocracy system is that there needs to be collateral-token, which is used for the settlement of all value transfers within the system. This collateral token is required to fulfill the following to conditions:
1. it can easily be forked into the different branches.
2. the token needs to a proper value proposition, as users expect the token to keep a steady value

The first point is essential for the workings of the system. The second one is important as users of the ecosystem should be very comfortable holding the token used for any interactions. This underlying collateral token should have the volatility risks spread out well and should have a good value proposition. Using an Exchange-Traded-Fund(ETF) of tokens, which support the forkonomic protocol, as the collateral token is a good choice, as ETFs are known as tool for spreading risk and have a very good value proposition.

## Key Building Blocks

### Realit.io - asking for facts

Realit.io has built a platform, which increases the efficiency of arbitration. On this platform, people can request answers for their questions. Each time a question is asked, the asker needs to specify an arbitrator, who will make the final arbitration, in case the peers on the platform cannot find a consensus about the correct answers to the question. The consensus about a questions answer is found with the following procedure: Peers from the platform can provide the question's answer and a bond. If someones see that an incorrect answer was provided, then they can correct the answer by providing the correct answer and a new bond. This new bond needs to have twice the previous bond size. This game escalates pretty quickly, as bond size will grow exponentially. If the bonding reaches a certain threshold, it gets profitable for the participants to pay the arbitrator and let the arbitrator decided about the final answer to the question. Peers, which bonded on an incorrect answer lose their bonds and peers bonding on the correct answer get a reward.

Overall this process makes arbitration very efficient for the arbitrator and reduces the costs for getting an answer to general knowledge questions or arbitrations on the blockchain ecosystem.

While realit.io is very efficient and effective, there might be the need for different escalation games depending on the application. If there are at some point several platforms with different escalation games, the different forkonomic dapps could use the platform fitting the best to their needs.
Especially, it might be better in some usecases to play these escalation games in a forkable token, and not just with Ether. It has the benefit that escalation games participants have a natural protection about the bad decision of arbitrators and hence are more willing to escalate these escalation games.

### Forkonomic-protocol - doing arbitration 

Any question entering the forkonomic system should get asked on Realit.io with an whitelisted arbitrator on a current forkonomic branch. 
Now, there are 3 outcomes:
1. The question gets answered without an escalation game. 
This should be the usual case. Here, the correct answer is provided from the beginning. The smart contracts of the forkonomic system can easily read the correct answer from realit.io.
2. The question gets escalated to the arbitrator.
Now, the answer needs to be provided by the arbitrator. In most cases, the arbitrator will tell the truth and the dishonest answer provider gets slashed and loses his bond. The smart contracts of the forkonomic system can easily read the correct answer from realit.io. 
3. The question gets escalated to the arbitrator and the arbitrator is dishonest.
Such a situation should create a big social outcry. People would get aware of this malicious behavior of the arbitrator and they would start to create new branches delisting the arbitrator from the system. The smart contracts of the forkonomic system will only read the answer from realit.io on branches, where the arbitrator is still listed. For the other branches, the question needs to be resubmitted to realit.io with another valid arbitrator. Then the escalation game starts again and the process repeats itself.


The forkonomic-protocol does the ultimate arbitration of the arbitrator list. As pointed out before, the forkonomic system allows anyone to fork the system and introduce a new branch with a new list of arbitrators. Whenever someone feels that the arbitrator list should be altered, may it due to an incorrect behavior of the arbitrator or due to an addition of further arbitrators, a new branch can be added on a smart contract level (cf. ForkonomicSystem.sol). The addition of the new branch is basically free, but getting people adapting to it is the real cost. 
A new branch will only get adaption, if it benefits the Forknomic-system, other branches will be left behind quickly. This benefit could be the elimination of bad arbitrators or a well-discussed addition of new arbitrators. This is a reinforcement system, where bad decision won't be adapted, as they hurt the system and good decision will be adapted, as they benefit the system. Others might describe this system as a token curated list of a good decision.
The beauty of such a system is that the logic for choosing a branch is not determined in smart contracts. The logic is determined on a social basis. This is powerful, as no constant logic has the capability to fit all new conditions and can constantly make the right decisions. However, the social decision logic is flexible enough to make the right decision at the right point of time amd still the system is robust enough that these decisions can be coordinated well.

In this system, any interaction with a smart contract always happens on a specified branch chosen by the user. Usually, there should be only one main branched used by all participants. Only in case of a controversy, there might be several viable branches. In this situation, the user has to options:
1. user might evaluate the controversy and chooses a specific branch for all further interaction.
2. user might make his transaction on several branches in order to ensure that the transaction is happening on the branch, which will get the best adaption later.  

As the second option comes with an additional gas cost, the users will in most situations choose a specific branch, the branch they expect to become the next main branch. Of course, they will not choose any malicious branch, as this branch would not get any increased adaption, as long as people can identify the malicious arbitrators.

Dapp building on top of the forkonomic system will be done in such a manner that they can easily deal with all the different branches created. If these dapps have their own token, they can also make this token compatible with the forkonomic-token standard. This standard is quite the same as the ERC20 token standard, but with the difference that tokens always need to be transferred on a specified branch (cf. ForkonomicToken.sol). These branches need to be in coherence with the branch system of the whole forkonomic system.

### Forkonomics-ETF

If there are any successful dapps using the forkonomic-token protocol, then these tokens can be bundled in a forkonomic-Exchange-Traded-Fund (forkonomic-ETF). Of course, the forkonomic-ETF would have its own token, tracking the ETFs value. This token would also follow the forkonomic protocol. Forkonomic tokens can be added to the ForkonomicETF by the following process:
1. Anyone can make a proposal to add or remove tokens to the fund
2. The fund will take the proposal and make a question to realit.io and a current arbitrator, whether this proposal should be accepted.
3. Realit.io will answer this question
4. The funds smart-contract will read the answer from realit.io. If the arbitrator is still white-listed on this particular branch and the answer from realit.io is yes, then we will add the token to the forkonomics fund. The token provider will be compensated with forkonomic-tokens.

This process allows a fund management based on an arbitrator managing the fund. This is a very safe mechanism, as any bad  arbitrator decisions can be reverted by the the community. The community can simply decided to use the forkonomics-system as back-up to branch-off the arbitrator.

The Forkonomics-ETF plays a central role in the Forkonomics ecosystem. The forkonomic system is a platform for value transfers conditional to propositions or arbitrator decisions. As mentioned before, in order to use subjectivocracy all payments need to be performed with a forkable token as collateral. Probably, the Forkonomics-ETF token is the preferred collateral in the ecosystem, as it backed by stocks with relatively well spread risks.

The forkonomic-ETF will hold forknomoic-tokens according to some rulset. Although this rule set will be adapted over time to reflect the growth of the eco system, some rules will stay constant:

1. The forkonomic-token needs to be fully compatible with the branching mechanism and the adapted ERC20-functionality as described in ForknomicToken.sol
2. If the issuing company makes profit on a branch X, then this profit needs to be used to increase the issued token value on exactly the same branch, not a competipor branch. 
3. Additional requirements on reporting figures and revenue streams will be adapted in time. TBD.

The first rule ensure that the ETF can itself follow the forkonomics protocol and the second rule ensures that the ETF will have the most value on the most used/valueable branch of the forkonomic system.

###	RealityToken - Bootstrapping the system

The RealityToken, has a very special role. It will not just be the very first token being added to the forkonomic-ETF, it will help bootstrap the whole Forkonomic system. 
The value proposition of RealityToken will come from the fact that the system will require every arbitrator to receive the payment for the arbitration in RealityToken and they have to burn have of the received tokens. If the arbitrators do not burn the tokens, they will be forked out of the list of trusted arbitrators.
If questions on realit.io will not be esclated to the arbitrator, then no realityTokens will be burned.

Additionally, RealityTokens will have value, as they will be the initial dominat currency of the Forkonomic-System. Although this might change over time, when the forkonomic-ETF will become the dominat currency of the system.

RealityTokens will be distributed in a unique manner: All tokens are created at once during the contract creation, but they are stored in so called distribution contracts (cf. Distribution.sol). Arbitrators can arbitrate that the distribution contracts should fund specific projects of the eco-system. This means that the tokens will not be sold via an ICO, but they are used as reward mechansim for building infrastructure. Although the arbitrators have quite some power in the fund distribution, the utlimtate decision is made by the collective of all token-holders, as they have the power to change the arbitrators.

### Forknomonics - Cooperations

We can imagine a wide spread of application of this forkonomics system. Here, we wanna list the most obvious dapps, which can be built

#### Examples:

1. Insurances: Hurricane parametric insurance, Flood parametric insurance, fire insurances, car insurances, employment insurances.
1.1 A fund which buys well-spread insurance policies with only a fractional covering of the policies involved. The risks should be well of the policies should be so well spread that a fraction coverage is justified, as it currently is in the traditional insurance industry via Basel 3.
2. Derivative Markets: All kind of markets for trading derivatives in a decentralized fashion can be built. These derivatives could be once tokenized and then later freely be traded on any exchanges, also plasma exchanges
2.1 Prediction Markets
3. Gambling applications
4. Arbitration between contract partners
5. Arbitration platform for gitcoin like projects
6. Stable coins with truely decentralized price feed
7. Tokenization of Events
8. Bonding platform for arbitrators: Arbitrators will only be able to withdraw their bond in the future, if they are still arbitrator on this branch. This will incentive arbitrators to act honestly.
9. ...



### Governance in Forknomonics

Forkonomics takes a very practical approach for the governance system. Dapps in this system have a unique way to be governed: These dapps can simply ask the dedicated arbitrators, which decision the dapp should take. This enables a very efficient and fast decision making. Only if there is a bigger disagreement within the community with the decisions of the arbitrators, then the decision can be undone in another fork and the arbitrator can be altered.
This process is quite similar as decision are taken in modern societies. Usually, the nation trust elected leaders, which do most of the decision making. Only, if there is a public outcry about specific decision, the decision can be undone and the person making the bad decision will be removed from their mighty positions. 

### Timeline:

### Current code:

Take a look at the repo: ... for gnosis scalar markets based on forkonomics.
