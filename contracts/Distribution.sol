pragma solidity ^0.4.15;

import "./ForkonomicToken.sol";
import "./RealityCheck.sol";

contract Distribution{
   mapping(address => uint256) balances;
   address public owner;
   bool isFinished;
   ForkonomicToken public forkonomicToken;
   RealityCheck public realityCheck;
   RealityFund public realityFund;

   event Withdraw(bytes32 hashid, address user);

   modifier isOwner(){
    require(msg.sender == owner);
    _;
   }


   modifier notYetFinished(){
    require(!isFinished);
    _;
   }

    uint256 public template_id=5;
    uint256 public min_bond;
    uint32 public min_timeout=0;
    uint32 public opening_ts;
    string public realityCheckQuestion;
    bytes32 public content_hash;


   //Constructor sets the owner of the Distribution
   constructor()
   public {
     opening_ts = uint32(now+30 days);
     realityCheckQuestion = "Which contract should be able to withdraw funds?";
     content_hash = keccak256(abi.encodePacked(template_id, opening_ts, realityCheckQuestion));     
     owner = msg.sender;
   }

   function setRealityVariables(ForkonomicToken _forkonomicToken, RealityCheck _realityCheck, RealityFund _realityFund)
   public {
      forkonomicToken = _forkonomicToken;
      realityFund = _realityFund;
      realityCheck = _realityCheck;
   }
   //@param users list of users that should be rewarded
   //@param fundAmount list of amounts the users should be funded with
   function injectReward(address[] user, uint[] fundAmount_)
   isOwner()
   notYetFinished()
   public
   {
      for(uint i=0; i<user.length;i++)
          balances[user[i]] = fundAmount_[i];
   }

   function finalize()
   isOwner()
   public{
     isFinished = true;
   }

   // param hashid_ hashid_ should be the hash of the branch 
   function withdrawReward(bytes32 hashid_) public {
     forkonomicToken.transfer(msg.sender, balances[msg.sender], hashid_);
     balances[msg.sender] = 0;
     emit Withdraw(hashid_, msg.sender);
   }
    // param hashid_ hashid_ should be the hash of the branch 
   function delayDistributionLeftOverTokens(bytes32 hashid_, bytes32 question_id, address arbitrator, address fundsReceiver) public {

    // ensure that arbitrator is white-listed
    require(realityFund.arbitrator_whitelists(hashid_, arbitrator));
    // ensure that fundsReceiver is the right party and that the question_ID fits
    require(fundsReceiver == address(realityCheck.getFinalAnswerIfMatches(question_id, content_hash, arbitrator, min_timeout, min_bond)));

     forkonomicToken.transfer(fundsReceiver, forkonomicToken.balanceOf(this, hashid_), hashid_);
     emit Withdraw(hashid_, fundsReceiver);
   }
}