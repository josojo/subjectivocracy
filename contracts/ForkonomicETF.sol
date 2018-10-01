pragma solidity ^0.4.22;

import "./ForkonomicToken.sol";
import "@realitio/realitio-contracts/truffle/contracts/RealityCheck.sol";
import "./ForkonomicSystem.sol";


contract ForkonomicETF is ForkonomicToken {
    //events
    event NewDealProposed(
        bytes32 branch,
        address forkonomicToken,
        int balanceChange_,
        int  compensation,
        address sender);

    //constant variables
    string public constant name = "ForkonomicsETF";
    string public constant symbol = "FETF";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places

    //interfaces
    RealityCheck public realityCheck;

    // branch => token => change
    mapping(bytes32=>mapping(address=>int)) public fundHoldingChange; 

    // branch => token => change
    mapping(bytes32=>int) public fETFbalanceChange; 
    
    uint256 public template_id=5;
    uint256 public minBond = 50000000000000000;
    uint32 public minTimeout= 1 days;
    uint32 public opening_ts;
    uint256 public minQuestionFunding =50000000000000000; // minimul payment for a funding request is 0.05 ETH. This is used in realitycheck
    bytes32 constant Proposal_HASH = "214"; // hash for identifying the deposited funds

    constructor(
        RealityCheck realityCheck_, 
        ForkonomicSystem fSystem_,
        address [] funding
    )
    ForkonomicToken(fSystem_, funding) 
    public {
        realityCheck = realityCheck_;
    }

    // @dev This function takes a investment proposal and makes a question
    // in realityCheck to arbitrate about this investment request.
    function proposeInvestment(bytes32 branch, address forkonomicToken, int balanceChange, int compensation, address arbitrator) 
    public payable {
        // check request for logic
        if (balanceChange > 0) {
            require(compensation < 0);
            require(ForkonomicToken(forkonomicToken).boxTransferFrom(msg.sender, this, uint(balanceChange), branch, NULL_HASH, Proposal_HASH));
        } else {
            require(compensation > 0);
            transferFrom(msg.sender, this, uint(compensation), branch);

        }
        //ensure that question can be funded
        require(msg.value >= minQuestionFunding);

        //posting question
        opening_ts = uint32(now + 30 days);
        bytes32 deal = keccak256(abi.encodePacked(branch, forkonomicToken, balanceChange, compensation, msg.sender));
        string memory question = string(abi.encodePacked("From all offers for the fETF, the following deal was the best:", bytes32ToString(bytes32(deal)), "?"));
        //bytes32 contentHash = keccak256(abi.encodePacked(template_id, opening_ts, question));     
        realityCheck.askQuestion.value(5*1000000000000)(0, question, arbitrator, minTimeout, opening_ts, 0);
        emit NewDealProposed(branch, forkonomicToken, balanceChange, compensation, msg.sender);
    }

    // @dev executes a previously handed in investement request based on the arbitrators decision.
    // 
    function executeInvestmentRequeset(bytes32 questionId, bytes32 executionbranch, bytes32 originalbranch, address forkonomicToken, int balanceChange_, int compensation, address arbitrator)
    public {
        // check that original branch is a father of executionbranch:
        require(fSystem.isFatherOfBranch(originalbranch, executionbranch));

         // ensure that arbitrator is white-listed
        require(fSystem.isArbitratorWhitelisted(arbitrator, executionbranch));

        // get answer from relaityCheck
        opening_ts = uint32(now+30 days);
        bytes32 deal = keccak256(abi.encodePacked(originalbranch, forkonomicToken, balanceChange_, compensation, msg.sender));
        string memory question = string(abi.encodePacked("From all offers for the fETF, the following deal was the best:", bytes32ToString(bytes32(deal)), "?"));
        bytes32 contentHash = keccak256(abi.encodePacked(template_id, opening_ts, question));     
        uint ans = uint(realityCheck.getFinalAnswerIfMatches(questionId, contentHash, arbitrator, minTimeout, opening_ts));
        // ensures that balances are not withdrawn form a branch older than the end of the questionanswer period. 
        require(fSystem.branchTimestamp(executionbranch) >= minTimeout+fSystem.WINDOWTIMESPAN());
        
        // processing the actual fund transfers
        if (ans == 0) {
            //if the request has not been accepted
            if (balanceChange_ > 0) {
                require(!ForkonomicToken(forkonomicToken).hasBoxWithdrawal(msg.sender, NULL_HASH, executionbranch, originalbranch)); 
                require(ForkonomicToken(forkonomicToken).boxTransfer(msg.sender, uint(balanceChange_), executionbranch, Proposal_HASH, NULL_HASH));
                ForkonomicToken(forkonomicToken).recordBoxWithdrawal(NULL_HASH, uint(balanceChange_), executionbranch);
            } else {
                require(!hasBoxWithdrawal(msg.sender, NULL_HASH, executionbranch, originalbranch)); 
                require(transfer(msg.sender, uint(compensation), executionbranch));
                recordBoxWithdrawal(NULL_HASH, uint(compensation), executionbranch);
            }
        } else {
            //if request has been accepted
            // credit new fETF-tokens
            if (balanceChange_ > 0){
                require(!hasBoxWithdrawal(msg.sender, NULL_HASH, executionbranch, originalbranch)); 
                balanceChange[executionbranch][keccak256(abi.encodePacked(msg.sender, NULL_HASH))] += compensation;
                fETFbalanceChange[executionbranch] += compensation;
                recordBoxWithdrawal(NULL_HASH, uint(compensation), executionbranch);
            } else {
                //send out the tokens to requestStarter, burn credited fETF-tokens
                require(!ForkonomicToken(forkonomicToken).hasBoxWithdrawal(msg.sender, NULL_HASH, executionbranch, originalbranch));
                require(ForkonomicToken(forkonomicToken).transfer(msg.sender, uint(balanceChange_), executionbranch));
                fETFbalanceChange[executionbranch] += compensation;
                ForkonomicToken(forkonomicToken).recordBoxWithdrawal(NULL_HASH, uint(balanceChange_), executionbranch);
            }
        }
    }
   
    function redeemRealityFundTokens(bytes32 branch, uint amount, address [] forkonomicTokens) public {
        // transfer tokens, which are about to be redeemed
        require(transferFrom(msg.sender, this, amount, branch));

        //calculate the total amount of outstanding ForkonomicETF-tokens
        int256 amountOutstandingETFToken = 0;
        bytes32 hashIteration = branch;
        while (hashIteration != fSystem.genesisBranchHash()) {
            amountOutstandingETFToken += fETFbalanceChange[hashIteration];
            hashIteration = fSystem.getParentHash(hashIteration);
        }

        // make the payout for all tokens
        for (uint i=0; i < forkonomicTokens.length; i++) {
            uint256 holdings = ForkonomicToken(forkonomicTokens[i]).balanceOf(this, branch);
            //make safe mul
            require(ForkonomicToken(forkonomicTokens[i]).transfer(msg.sender, amount * holdings / uint(amountOutstandingETFToken), branch));
        }

    }

    function bytes32ToString (bytes32 data) public returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j < 32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
}