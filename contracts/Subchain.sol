pragma solidity ^0.4.22;

import "./ForkonomicToken.sol";
import "./ForkonomicSystem.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
/* THis contract allows people to use the ERC20 standard for their forkonomicTokens. 
The ERC20 stnadard can be used and all answers from the abritrator are processedvery quickly,
until he is getting malicious. Then this needs to be reported by challengeing the arbitrator
in this contracts.

Once the arbitrator is challenged, eveyone needs to withdraw their funds using the forkonomic 
protocoll. Smart contracts using this token as collateral should aksi process the tokens
 with the usual forkonomic protcoll and can no longer reley on this quick process."
*/

// bondedWorldView

contract SubChain is StandardToken {
    using SafeMath for uint256;

    bytes32 constant NULL_HASH = "";

    bool public isChallenged = false;
    ForkonomicSystem public fSystem;
    ForkonomicToken public collateral;
    bytes32 public fundingBranch;
    address public arbitrator;
    address public owner;
    address public challenger;
    uint256 public challengeTime;
    uint256 public bond;

    constructor( ForkonomicToken collateral_, ForkonomicSystem fSystem_,
        bytes32 fundingBranch_, address arbitrator_) public {
        collateral = collateral_;
        fSystem = fSystem_;
        fundingBranch = fundingBranch_;
        arbitrator = arbitrator_;
    }

    function providInitialBond (uint bond_) public {
        bond = bond_;
        require(collateral.transferFrom(arbitrator, this, bond, fundingBranch));
    }
    
    function deposit (uint amount) public {
        require(!isChallenged, "Subchain is already chalenged");
        require(collateral.transferFrom(msg.sender, this, amount, fundingBranch));
        balances[msg.sender] = balances[msg.sender].add(amount);
    }
    
    function withdraw (uint amount) public {
        require(!isChallenged, "Subchain is already chalenged");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        require(collateral.transfer(msg.sender, amount, fundingBranch));
    }

    function challengeArbitrator () public {
        isChallenged = true;
        challenger = msg.sender;
        challengeTime = now;
        require(collateral.transferFrom(msg.sender, this, bond, fundingBranch), "transferFrom was not possible");
    }
     
    function withdrawAfterChallenge (uint amount, bytes32 branch) public {
        require(isChallenged, "not yet challenged");
        require(collateral.hasBoxWithdrawal(msg.sender, NULL_HASH, branch, fundingBranch));
        require(collateral.transfer(msg.sender, amount, branch));
        require(collateral.recordBoxWithdrawal(NULL_HASH, amount, branch));
    }   

    //arbitrator can withdraw his bond + challenger funds on all branches, where he is still a valid arbitrato
    function withdrawalForArbitrator(bytes32 branch) public {
        require(isChallenged, "not yet challenged");
        require(fSystem.branchTimestamp(branch) + fSystem.WINDOWTIMESPAN() > challengeTime);
        require(fSystem.isArbitratorWhitelisted(arbitrator, branch));
        require(collateral.hasBoxWithdrawal(arbitrator, NULL_HASH, branch, fundingBranch));
        require(collateral.transfer(arbitrator, 2*bond, branch));
        require(collateral.recordBoxWithdrawal(NULL_HASH, 2*bond, branch));
    }

    //challenger can withdraw his bond + arbitrator funds on all branches,
    // where the arbitrator is no longer a valid arbitrato
    function withdrawalForChallenger(bytes32 branch) public {
        require(isChallenged, "not yet challenged");
        require(fSystem.branchTimestamp(branch) + fSystem.WINDOWTIMESPAN() > challengeTime, "challengingTime too early");
        require(!fSystem.isArbitratorWhitelisted(arbitrator, branch), "arbitrator is not white-listed");
        require(collateral.hasBoxWithdrawal(challenger, NULL_HASH, branch, fundingBranch), "hasBoxWithdrawal ==false");
        require(collateral.transfer(challenger, 2*bond, branch), "transfer failed");
        require(collateral.recordBoxWithdrawal(NULL_HASH, 2*bond, branch), " recordBoxWithdrawal failed");
    }
}