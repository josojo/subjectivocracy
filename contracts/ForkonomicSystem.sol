pragma solidity ^0.4.22;


contract ForkonomicSystem {

    event BranchCreated(bytes32 hash, bytes32 whiteList_id);

    bytes32 public NULL_HASH = "";
    uint32 public WINDOWTIMESPAN = 86400; 

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
    mapping(uint256 => bytes32[]) public windowBranches; // index to easily get all branch hashes for a window
    
    uint256 public genesisWindowTimestamp; // 00:00:00 UTC on the day the contract was mined
    bytes32 public genesisBranchHash=NULL_HASH;

    constructor()
    public {
        genesisWindowTimestamp = now - (now % WINDOWTIMESPAN);
        bytes32 genesisMerkleRoot = keccak256("I leave to several futures (not to all) my garden of forking paths");
        genesisBranchHash = keccak256(abi.encodePacked(genesisMerkleRoot, NULL_HASH));

        branchParentHash[genesisBranchHash] = NULL_HASH;
        branchArbitratorsID[genesisBranchHash] = NULL_HASH;
        branchTimestamp[genesisBranchHash] = now - (now % WINDOWTIMESPAN);
        branchWindow[genesisBranchHash] = 0;
        windowBranches[0].push(genesisBranchHash);
    }

    function createBranch(bytes32 parentBranchHash, bytes32 whitelist_id)
    public returns (bytes32) {

        bytes32 branchHash = keccak256(abi.encodePacked(parentBranchHash, whitelist_id));
        require(branchHash != NULL_HASH, "branch hash should not be the NULL_HASH");

        // Your branch must not yet exist, the parent branch must exist.
        // Check existence by timestamp, all branches have one.
        require(branchWindow[branchHash] == 0, "branch must not exist");
        require(parentBranchHash == genesisBranchHash || branchWindow[parentBranchHash] > 0, "parent branch must exist");

         // The window should be the window after the previous branch.
        uint256 window = branchWindow[parentBranchHash] + 1;
        require(now >= genesisWindowTimestamp + WINDOWTIMESPAN * window, "there must be one week delay between parent and son branch");

        branchParentHash[branchHash] = parentBranchHash;
        branchArbitratorsID[branchHash] = whitelist_id;
        //Either timestamp or window is not needed in this construction
        //branchTimestamp[branchHash] = genesisWindowTimestamp + WINDOWTIMESPAN * window;
        branchWindow[branchHash] = window;
        windowBranches[window].push(branchHash);

        emit BranchCreated(branchHash, whitelist_id);
        return branchHash;
    }

    function createArbitratorWhitelist(address[] arbitrators)
    public returns (bytes32) {
        // generate unique id;
        bytes32 prev_hash = keccak256(abi.encodePacked(arbitrators[0]));
        for (uint i=1; i < arbitrators.length; i++) {
            prev_hash = keccak256(abi.encodePacked(prev_hash, arbitrators[i]));
        }
        //set abirtrator address as true    
        for (i = 0; i < arbitrators.length; i++) {
            arbitratorWhitelists[prev_hash][arbitrators[i]] = true;
        }
        return prev_hash;
    }

    function isArbitratorWhitelisted(address arb, bytes32 branch) 
    public constant returns (bool) {
        return arbitratorWhitelists[branchArbitratorsID[branch]][arb];
    }
 
    function isBranchInBetweenBranches(bytes32 investigationHash, bytes32 closerToRootHash, bytes32 fartherToRootHash)
    public constant returns (bool) {
        bytes32 iterationHash = closerToRootHash;
        while (iterationHash != fartherToRootHash) {
            if (investigationHash == iterationHash) {
                return true;
            } else {
                iterationHash = branchParentHash[iterationHash];
            }
        }
        return false;
    }

    function isBranchCreatedAfterTS(uint256 ts, bytes32 branch) public view returns(bool) {
        if (branchWindow[branch] * WINDOWTIMESPAN + genesisWindowTimestamp >= ts - WINDOWTIMESPAN)
            return true;
        else 
            return false;
    }

    function doesBranchExist(bytes32 branch) public view returns(bool) {
        return (branch == genesisBranchHash || branchWindow[branch] > 0);
    }

    function isFatherOfBranch(bytes32 father, bytes32 son)
    public constant returns (bool) {

        while (son != father) {
            son = branchParentHash[son];
            if (son == genesisBranchHash)
                if (father == genesisBranchHash)
                    return true;
                else
                    return false;
        }
        return true;
    }
}
