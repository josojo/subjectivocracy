pragma solidity ^0.4.22;

import "./ForkonomicToken.sol";
import "./RealityCheck.sol";


contract Distribution {

    mapping(address => uint256) public balances;
    address public owner;
    bool isFinished;

    ForkonomicToken public forkonomicToken;
    RealityCheck public realityCheck;
    ForkonomicSystem public fSystem;
   
    event Withdraw(bytes32 hashid, address user);

    modifier isOwner() {
        require (msg.sender == owner, "sender not owner");
        _;
    }

    modifier notYetFinished() {
        require(!isFinished, "setup is already finished");
        _;
    }

    uint256 public templateId=5;
    uint256 public minBond;
    uint32 public minTimeout;
    uint32 public openingTs;
    string public realityCheckQuestion;
    bytes32 public contentHash;

   //Constructor sets the owner of the Distribution
    constructor() public {    
        owner = msg.sender;
    }

    // variables, which we were not able to hand over to the constructor
    function setRealityVariables(ForkonomicToken _forkonomicToken, RealityCheck _realityCheck, ForkonomicSystem _fSystem)
    public 
    isOwner()
    notYetFinished()
    {
        forkonomicToken = _forkonomicToken;
        fSystem = _fSystem;
        realityCheck = _realityCheck;
    }

     //@param users list of users that should be rewarded
     //@param fundAmount list of amounts the users should be funded with
    function injectReward(address[] user, uint[] fundAmount_)
    public
    isOwner()
    notYetFinished()
    {
        for (uint i=0; i < user.length; i++)
            balances[user[i]] = fundAmount_[i];
    }

     // to be called once all rewards are injected
    function finalize()
    public
    isOwner()
    {
        isFinished = true;
    }

    function askRealityCheck(address arbitrator) public payable returns (bytes32) {
        openingTs = uint32(now+30 days);
        minTimeout = 1000;
        realityCheckQuestion = string(abi.encodePacked("Which contract should be able to withdraw funds from ", this, "?"));
        contentHash = keccak256(abi.encodePacked(templateId, openingTs, realityCheckQuestion)); 
        return realityCheck.askQuestion(0, realityCheckQuestion, arbitrator, minTimeout, openingTs, 0);
    }

     // param hashid_ hashid_ should be the hash of the branch 
    function withdrawReward(bytes32 hashid_) public {
        forkonomicToken.transfer(msg.sender, balances[msg.sender], hashid_);
        balances[msg.sender] = 0;
        emit Withdraw(hashid_, msg.sender);
    }
  
    // param branch branch should be the hash of the branch for receiving the money
    function delayedDistributionLeftOverTokens(bytes32 branch, bytes32 questionId, address arbitrator, address fundsReceiver)
    public {
      // ensure that arbitrator is white-listed
        require(fSystem.isArbitratorWhitelisted(arbitrator, branch));
        // ensure that fundsReceiver is the right party and that the question_ID fits
        require(fundsReceiver == address(realityCheck.getFinalAnswerIfMatches(questionId, contentHash, arbitrator, minTimeout, minBond)));
        // ensures that balances are not withdrawn form a branch older than the end of the questionanswer period. 
        require(fSystem.branchTimestamp(branch) >= minTimeout+fSystem.WINDOWTIMESPAN());
        // send acutal funds to another distribution contract
        require(forkonomicToken.transfer(fundsReceiver, forkonomicToken.balanceOf(this, branch), branch));

        emit Withdraw(branch, fundsReceiver);
    }
}