pragma solidity ^0.4.6;
import "./ForkonomicsInterface.sol";

contract ForkonomicSystem{

    event BranchCreated(bytes32 hash, bytes32 whiteList_id);

 
    bytes32 constant NULL_HASH = "";
    address constant NULL_ADDRESS = 0x0;

    mapping(bytes32=>mapping(address=>bool)) public arbitrator_whitelists;
 
    struct Branch {
        bytes32 parent_hash; // Hash of the parent branch.
        bytes32 arbitrator_whitelist;
        uint256 timestamp; // Timestamp branch was mined
        uint256 window; 
    }
    mapping(bytes32 => Branch) branches;

 
    mapping(uint256 => bytes32[]) public window_branches; // index to easily get all branch hashes for a window
    uint256 public genesis_window_timestamp; // 00:00:00 UTC on the day the contract was mined
    bytes32 public genesis_branch_hash=NULL_HASH;
    mapping(address => mapping(address => mapping(bytes32=> uint256))) allowed;

    function createArbitratorWhitelist(address[] arbitrators) {
        // generate unique id;
        bytes32 prev_hash = keccak256(abi.encodePacked(arbitrators[0]));
        for(uint i=1;i<arbitrators.length;i++){
            prev_hash = keccak256(abi.encodePacked(prev_hash, arbitrators[i]));
        }
        //set abirtrator address as true    
        for( i=0;i<arbitrators.length;i++){
            arbitrator_whitelists[prev_hash][arbitrators[i]] = true;
        }
    }

    function isArbitratorWhitelisted(address arb, bytes32 branch) returns (bool) {
        return arbitrator_whitelists[branch][arb];
    }

    constructor()
    public {
        genesis_window_timestamp = now - (now % 86400);
        bytes32 genesis_merkle_root = keccak256("I leave to several futures (not to all) my garden of forking paths");
        genesis_branch_hash = keccak256(abi.encodePacked(NULL_HASH, genesis_merkle_root, NULL_ADDRESS));
        branches[genesis_branch_hash] = Branch(NULL_HASH, NULL_HASH, now, 0);
        window_branches[0].push(genesis_branch_hash);
    }

    function createBranch(bytes32 parent_branch_hash, bytes32 whitelist_id)
    public returns (bytes32) {

        bytes32 branch_hash = keccak256(abi.encodePacked(parent_branch_hash, whitelist_id));
        require(branch_hash != NULL_HASH);

        // Your branch must not yet exist, the parent branch must exist.
        // Check existence by timestamp, all branches have one.
        require(branches[branch_hash].timestamp == 0);
        require(branches[parent_branch_hash].timestamp > 0);

        // The window should be the window after the previous branch.
        // You can come back and add a window after it has passed.
        // However, usually you wouldn't want to do this as it would throw away a lot of history.
        uint256 window = branches[parent_branch_hash].window + 1;

        branches[branch_hash] = Branch(parent_branch_hash, whitelist_id, now, window);
        window_branches[window].push(branch_hash);
        emit BranchCreated(branch_hash, whitelist_id);
        return branch_hash;
    }
 
    function getWindowBranches(uint256 window)
    public constant returns (bytes32[]) {
        return window_branches[window];
    }

    function getParentHash(bytes32 hash)
    public returns (bytes32){
        return branches[hash].parent_hash;
    }

    function getTimestampOfBranch(bytes32 hash)
    public returns (uint256){
        return branches[hash].timestamp;
    }

    function getWindowOfBranch(bytes32 _branchHash)
    public constant returns (uint id) {
        return branches[_branchHash].window;
    }
   
    function isBranchInBetweenBranches(bytes32 investigationHash,bytes32 closerToRootHash, bytes32 fartherToRootHash)
    public constant returns (bool) {
        bytes32 iterationHash = closerToRootHash;
        while (iterationHash != fartherToRootHash) {
            if (investigationHash == iterationHash) {
                return true;
            } else{
                iterationHash = branches[iterationHash].parent_hash;
            }
        }
        return false;
    }
}
