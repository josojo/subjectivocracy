pragma solidity ^0.4.6;
import "./ForkonomicsInterface.sol";

contract ForkonomicSystem{

    event BranchCreated(bytes32 hash, bytes32 whiteList_id);

    bytes32 constant NULL_HASH = "";
    address constant NULL_ADDRESS = 0x0;

    // index_arbitrators => arbitrator => isSelected
    mapping(bytes32=>mapping(address=>bool)) public arbitratorWhitelists;
    // branch => parent_branch
    mapping(bytes32 =>  bytes32) public branchParentHash;
    // branch => timestamp
    mapping(bytes32 =>  uint ) public branchTimestamp;
    // branch => window
    mapping(bytes32 =>  uint ) public branchWindow;
    // branch => id
    mapping(bytes32 => bytes32) public branchArbitratorsID;
    // window => branches[]
    mapping(uint256 => bytes32[]) public window_branches; // index to easily get all branch hashes for a window
    
    uint256 public genesis_window_timestamp; // 00:00:00 UTC on the day the contract was mined
    bytes32 public genesis_branch_hash=NULL_HASH;
    

    constructor()
    public {
        genesis_window_timestamp = now - (now % 86400);
        bytes32 genesis_merkle_root = keccak256("I leave to several futures (not to all) my garden of forking paths");
        genesis_branch_hash = keccak256(abi.encodePacked(NULL_HASH, genesis_merkle_root, NULL_ADDRESS));

        branchParentHash[genesis_branch_hash] = NULL_HASH;
        branchArbitratorsID[genesis_branch_hash] = NULL_HASH;
        branchTimestamp[genesis_branch_hash] = now;
        branchWindow[genesis_branch_hash] = 0;
        window_branches[0].push(genesis_branch_hash);
    }

    function createBranch(bytes32 parent_branch_hash, bytes32 whitelist_id)
    public returns (bytes32) {

        bytes32 branch_hash = keccak256(abi.encodePacked(parent_branch_hash, whitelist_id));
        require(branch_hash != NULL_HASH);

        // Your branch must not yet exist, the parent branch must exist.
        // Check existence by timestamp, all branches have one.
        require(branchTimestamp[branch_hash] == 0);
        require(branchTimestamp[parent_branch_hash] > 0);

        // The window should be the window after the previous branch.
        // You can come back and add a window after it has passed.
        // However, usually you wouldn't want to do this as it would throw away a lot of history.
        uint256 window = branchWindow[parent_branch_hash] + 1;

        branchParentHash[branch_hash] = parent_branch_hash;
        branchArbitratorsID[branch_hash] = whitelist_id;
        branchTimestamp[branch_hash] = now;
        branchWindow[branch_hash] = window;
        window_branches[window].push(branch_hash);

        emit BranchCreated(branch_hash, whitelist_id);
        return branch_hash;
    }
    function createArbitratorWhitelist(address[] arbitrators)
    public {
        // generate unique id;
        bytes32 prev_hash = keccak256(abi.encodePacked(arbitrators[0]));
        for(uint i=1;i<arbitrators.length;i++){
            prev_hash = keccak256(abi.encodePacked(prev_hash, arbitrators[i]));
        }
        //set abirtrator address as true    
        for( i=0;i<arbitrators.length;i++){
            arbitratorWhitelists[prev_hash][arbitrators[i]] = true;
        }
    }

    function isArbitratorWhitelisted(address arb, bytes32 branch) 
    public constant returns (bool) {
        return arbitratorWhitelists[branchArbitratorsID[branch]][arb];
    }
 
    function getWindowBranches(uint256 window)
    public constant returns (bytes32[]) {
        return window_branches[window];
    }

    function getParentHash(bytes32 hash)
    public constant returns (bytes32){
        return branchParentHash[hash];
    }

    function getTimestampOfBranch(bytes32 hash)
    public constant returns (uint256){
        return branchTimestamp[hash];
    }

    function getWindowOfBranch(bytes32 hash)
    public constant returns (uint id) {
        return branchWindow[hash];
    }
   
    function isBranchInBetweenBranches(bytes32 investigationHash, bytes32 closerToRootHash, bytes32 fartherToRootHash)
    public constant returns (bool) {
        bytes32 iterationHash = closerToRootHash;
        while (iterationHash != fartherToRootHash) {
            if (investigationHash == iterationHash) {
                return true;
            } else{
                iterationHash = branchParentHash[iterationHash];
            }
        }
        return false;
    }

    function getArbitratorIdentifierOfBranch(bytes32 hash)
    public constant returns (uint id) {
        return branchWindow[hash];
    }

    function isFatherOfBranch(bytes32 father, bytes32 son)
    public constant returns (bool) {
        while(son!= father){
            son = branchParentHash[son];
            if(son == genesis_branch_hash)
                return false;
        }
        return true;
    }
}
