pragma solidity ^0.4.6;
import "./ForkonomicToken.sol";
import "./RealityCheck.sol";
import "./ForkonomicSystem.sol";

contract ForkonomicETF is ForkonomicToken {

    event NewDealProposed(bytes32 branch, address forkonomicToken, int balanceChange,int  compensation,address sender);
    string public constant name = "ForkonomicsETF";
    string public constant symbol = "FETF";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    RealityCheck public realityCheck;
    ForkonomicSystem public fSystem;
    // branch => token => change
    mapping(bytes32=>mapping(address=>int)) public fund_holdings_changes; 

    // branch => token => change
    mapping(bytes32=>int) public fETFbalanceChange; 

    uint256 public genesis_window_timestamp; // 00:00:00 UTC on the day the contract was mined
    bytes32 public genesis_branch_hash=NULL_HASH;
    constructor(RealityCheck realityCheck_, ForkonomicSystem fSystem_)
    public {
        fSystem = fSystem_;
        realityCheck = realityCheck_;
        genesis_window_timestamp = now - (now % 86400);
        bytes32 genesis_merkle_root = keccak256("I leave to several futures (not to all) my garden of forking paths");
        genesis_branch_hash = keccak256(abi.encodePacked(NULL_HASH, genesis_merkle_root, NULL_ADDRESS));
    }

    uint256 public template_id=0;
    uint256 public min_bond = 500000;
    uint32 public min_timeout=500000;
    uint32 public opening_ts;
    uint256 public minQuestionFunding =50000000000000000; 
    bytes32 constant Proposal_HASH = "214";

    // @dev This function takes a investment proposal and makes a question in realityCheck to arbitrat about this investment request.
    // 
    function proposeInvestment(bytes32 branch, address forkonomicToken, int balanceChange, int compensation, address arbitrator) 
    public payable {
    if(balanceChange>0){
        require(compensation<0);
        require(ForkonomicsInterface(forkonomicToken).boxTransferFrom(msg.sender, this, uint(balanceChange), branch,NULL_HASH, Proposal_HASH));
    } else{
        require(compensation>0);
        transferFrom(msg.sender, this, uint(compensation), branch);

    }
    require(msg.value>=minQuestionFunding);

     opening_ts = uint32(now+30 days);
     bytes32 deal = keccak256(abi.encodePacked(branch, forkonomicToken, balanceChange, compensation, msg.sender));
     string memory question = string(abi.encodePacked("Should the FETF take the deal:", bytesToString(bytes32(deal)),"?"));
     bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));     
     realityCheck.askQuestion.value(5*1000000000000)(0, question, arbitrator, min_timeout, opening_ts, 0);
     emit NewDealProposed(branch, forkonomicToken, balanceChange, compensation, msg.sender);
    }
    // @dev executes a previously handed in investement request based on the arbitrators decision.
    // 
    function executeInvestmentRequeset(bytes32 question_ID, bytes32 branch, address forkonomicToken, int balanceChange, int compensation, address arbitrator)
    public {

     // ensure that arbitrator is white-listed
    require(fSystem.arbitrator_whitelists(branch, arbitrator));

     opening_ts = uint32(now+30 days);
     bytes32 deal = keccak256(abi.encodePacked(branch, forkonomicToken, balanceChange, compensation, msg.sender));
     string memory question = string(abi.encodePacked("Should the FETF take the deal:", bytesToString(bytes32(deal)),"?"));
     bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));     
     uint ans = uint(realityCheck.getFinalAnswerIfMatches(question_ID, content_hash, arbitrator, min_timeout, opening_ts));

     //if the request has not been accepted
     if(ans == 0){
        if(balanceChange>0){
           require(ForkonomicsInterface(forkonomicToken).boxTransfer( msg.sender, uint(balanceChange), branch, Proposal_HASH, NULL_HASH));
        } else{
           require(transfer(msg.sender, uint(compensation), branch));
        }
     }
     else{
        // credit new fETF-tokens
        if(balanceChange>0){
             balance_change[branch][keccak256(abi.encodePacked(msg.sender, NULL_HASH))] += compensation;
             fETFbalanceChange[branch] += compensation;
        }
        //burn credited fETF-tokens
        else{
            require(ForkonomicsInterface(forkonomicToken).transfer(msg.sender, uint(balanceChange), branch));
            fETFbalanceChange[branch] += compensation;
        }
     }
    }
   
    function redeemRealityFundTokens(bytes32 branch, uint amount, address [] forkonomicTokens){
        require(transferFrom(msg.sender, this, amount, branch));

        int256 totalAmountOfRealityFundToken = 0;
        bytes32 hash_iteration = branch;
        while(hash_iteration != genesis_branch_hash){
            totalAmountOfRealityFundToken += fETFbalanceChange[hash_iteration];
            hash_iteration = fSystem.getParentHash(hash_iteration);
        }
        for(uint i=0;i<forkonomicTokens.length;i++){
            uint256 holdings = ForkonomicsInterface(forkonomicTokens[i]).balanceOf(this, branch);
            //make safe mul
            require(ForkonomicsInterface(forkonomicTokens[i]).transfer(msg.sender,amount*holdings/ uint(totalAmountOfRealityFundToken) ,branch));
        }
        fETFbalanceChange[branch] -= int(amount);

    }

    function bytesToString (bytes32 data) returns (string) {
    bytes memory bytesString = new bytes(32);
    for (uint j=0; j<32; j++) {
        byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[j] = char;
        }
    }
    return string(bytesString);
}
}
