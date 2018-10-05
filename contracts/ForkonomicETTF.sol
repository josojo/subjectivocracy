pragma solidity ^0.4.22;

import "./ForkonomicToken.sol";
import "@realitio/realitio-contracts/truffle/contracts/RealityCheck.sol";
import "./ForkonomicSystem.sol";


contract ForkonomicETTF is ForkonomicToken {
    //events
    event NewDealProposed(
        bytes32 branch,
        address forkonomicToken,
        int balanceChange_,
        int  compensation,
        address sender);

    //constant variables
    string public constant name = "ForkonomicsETTF";
    string public constant symbol = "FETTF";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places

    //interfaces
    RealityCheck public realityCheck;

    // branch => token => change
    mapping(bytes32 => mapping(address => int)) public fundHoldingChange; 

    // branch => token => change
    mapping(bytes32 => int) public fETTFbalanceChange; 
    
    uint256 public templateId=0;
    uint256 public minBond = 5000000000;
    uint32 public minTimeout= 1000;
    uint32 public openingTs;
    uint256 public minQuestionFunding =5000000000000000;
    
     // minimul payment for a funding request is 0.05 ETH. This is used in realitycheck

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
    function proposeInvestment(bytes32 branch, address forkonomicToken, int balanceChange, int compensation, address arbitrator, bytes32 fromBox) 
    public payable returns(bytes32) {
        //posting question
        openingTs = uint32(now + 30 days);
        bytes32 deal = keccak256(abi.encodePacked(branch, forkonomicToken, balanceChange, compensation, msg.sender));
        string memory question = string(abi.encodePacked("From all offers for the fETTF, the following deal was the best:", bytes32ToString(bytes32(deal)), "?"));
        //bytes32 contentHash = keccak256(abi.encodePacked(templateId, openingTs, question));     
        bytes32 questionId = realityCheck.askQuestion.value(5*1000000000000)(templateId, question, arbitrator, minTimeout, openingTs, 0);
      

        // check request for logic
        if (balanceChange > 0) {
            require(compensation < 0);
            require(ForkonomicToken(forkonomicToken).boxTransferFrom(msg.sender, this, uint(balanceChange), branch, fromBox, deal));
        } else {
           require(compensation > 0);
           transferFrom(msg.sender, this, uint(compensation), branch);

        }
        //ensure that question can be funded
        require(msg.value >= minQuestionFunding);

        emit NewDealProposed(branch, forkonomicToken, balanceChange, compensation, msg.sender);
        return questionId;
    }

    // @dev executes a previously handed in investement request based on the arbitrators decision.
    // 
    function executeInvestmentRequest(bytes32 questionId, bytes32 executionbranch, bytes32 originalbranch, address forkonomicToken, int balanceChange_, int compensation, address arbitrator, bytes32 fromBox)
    public {
        // check that original branch is a father of executionbranch:
        require(fSystem.isFatherOfBranch(originalbranch, executionbranch));

         // ensure that arbitrator is white-listed
        require(fSystem.isArbitratorWhitelisted(arbitrator, executionbranch));

        // get answer from relaityCheck
        bytes32 deal = keccak256(abi.encodePacked(originalbranch, forkonomicToken, balanceChange_, compensation, msg.sender));
        string memory question = string(abi.encodePacked("From all offers for the fETTF, the following deal was the best:", bytes32ToString(bytes32(deal)), "?"));
        bytes32 contentHash = keccak256(templateId, openingTs, question);     
        uint ans = uint(realityCheck.getFinalAnswerIfMatches(questionId, contentHash, arbitrator, minTimeout, minBond));

        // ensures that balances are not withdrawn form a branch older than the end of the questionanswer period. 
        //require(fSystem.branchTimestamp(executionbranch) >= minTimeout-fSystem.WINDOWTIMESPAN());
        
        // processing the actual fund transfers
        if (ans == 0) {
            //if the request has not been accepted
            if (balanceChange_ > 0) {
                require(ForkonomicToken(forkonomicToken).boxTransfer(msg.sender, uint(balanceChange_), executionbranch, deal, fromBox));
            } else {
                require(transfer(msg.sender, uint(compensation), executionbranch));
            }
        } else {
            //if request has been accepted
            // credit new fETTF-tokens
            if (balanceChange_ > 0) {
                require(!hasBoxWithdrawal(msg.sender, NULL_HASH, executionbranch, originalbranch)); 
                balanceChange[executionbranch][keccak256(abi.encodePacked(msg.sender, NULL_HASH))] += compensation;
                fETTFbalanceChange[executionbranch] += compensation;
                recordBoxWithdrawal(NULL_HASH, uint(compensation), executionbranch);
            } else {
                //send out the tokens to requestStarter, burn credited fETTF-tokens
                require(ForkonomicToken(forkonomicToken).transfer(msg.sender, uint(balanceChange_), executionbranch));
                fETTFbalanceChange[executionbranch] += compensation;
            }
        }
    }
   
    function redeemRealityFundTokens(bytes32 branch, uint amount, address [] forkonomicTokens) public {
        // transfer tokens, which are about to be redeemed
        require(transferFrom(msg.sender, this, amount, branch));

        //calculate the total amount of outstanding ForkonomicETTF-tokens
        int256 amountOutstandingETTFToken = 0;
        bytes32 hashIteration = branch;
        while (hashIteration != fSystem.genesisBranchHash()) {
            amountOutstandingETTFToken += fETTFbalanceChange[hashIteration];
            hashIteration = fSystem.branchParentHash(hashIteration);
        }

        // make the payout for all tokens
        for (uint i=0; i < forkonomicTokens.length; i++) {
            uint256 holdings = ForkonomicToken(forkonomicTokens[i]).balanceOf(this, branch);
            //make safe mul
            require(ForkonomicToken(forkonomicTokens[i]).transfer(msg.sender, amount * holdings / uint(amountOutstandingETTFToken), branch));
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

    function calcDealBytes(bytes32 branch, address forkonomicToken, int balanceChange, int compensation) 
    public returns(bytes32) {
        bytes32 deal = keccak256(abi.encodePacked(branch, forkonomicToken, balanceChange, compensation, msg.sender));
        return deal;
    }
}