pragma solidity ^0.4.6;

contract RealityFund {

    event Approval(address indexed _owner, address indexed _spender, uint _value, bytes32 branch);
    event Transfer(address indexed _from, address indexed _to, bytes32 _from_box, bytes32 _to_box, uint _value, bytes32 branch);
    event BranchCreated(bytes32 hash, bytes32 whiteList_id);

    string public constant name = "RealityFund";
    string public constant symbol = "RF";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places

    bytes32 constant NULL_HASH = "";
    address constant NULL_ADDRESS = 0x0;

    mapping(bytes32=>mapping(address=>bool)) arbitrator_whitelists;
    mapping(bytes32=>mapping(address=>int)) fund_holdings_changes; 

    struct Branch {
        bytes32 parent_hash; // Hash of the parent branch.
        bytes32 arbitrator_whitelist;
        uint256 timestamp; // Timestamp branch was mined
        uint256 window; // Day x of the system's operation, starting at UTC 00:00:00
        mapping(bytes32 => int256) balance_change; // user-account debits and credits
        mapping(bytes32 => int256) withdrawal_record;
    }
    mapping(bytes32 => Branch) public branches;

    // Spends, which may cause debits, can only go forwards.
    // That way when we check if you have enough to spend we only have to go backwards.
    mapping(bytes32 => uint256) public last_debit_windows; // index of last user debits to stop you going backwards

    mapping(uint256 => bytes32[]) public window_branches; // index to easily get all branch hashes for a window
    uint256 public genesis_window_timestamp; // 00:00:00 UTC on the day the contract was mined

    mapping(address => mapping(address => mapping(bytes32=> uint256))) allowed;

    function createArbitratorWhitelist(address[] arbitrators) {
        for(uint i=0;i<arbitrators.length;i++)
            arbitrator_whitelists[keccak256(arbitrators)][arbitrators[i]] = true;
    }

    function isArbitratorWhitelisted(address arb, bytes32 branch) returns (bool) {
        return arbitrator_whitelists[branch][arb];
    }

    constructor()
    public {
        genesis_window_timestamp = now - (now % 86400);
        bytes32 genesis_merkle_root = keccak256("I leave to several futures (not to all) my garden of forking paths");
        bytes32 genesis_branch_hash = keccak256(NULL_HASH, genesis_merkle_root, NULL_ADDRESS);
        branches[genesis_branch_hash] = Branch(NULL_HASH, NULL_HASH, now, 0);
        window_branches[0].push(genesis_branch_hash);
    }

    function createBranch(bytes32 parent_branch_hash, bytes32 whitelist_id)
    public returns (bytes32) {

        bytes32 branch_hash = keccak256(parent_branch_hash, whitelist_id);
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

    function createBranchAndChangeFunding(bytes32 parent_branch_hash, bytes32 whitelist_id, address[] forkonomicToken, int[] balanceChange, int[] compensationForBlanceChange) 
    public returns (bytes32) {

        //Todo incorporate balance changes into hash
        bytes32 branch_hash = keccak256(parent_branch_hash, whitelist_id);
        require(branch_hash != NULL_HASH);

        // Your branch must not yet exist, the parent branch must exist.
        // Check existence by timestamp, all branches have one.
        require(branches[branch_hash].timestamp == 0);
        require(branches[parent_branch_hash].timestamp > 0);

        // The window should be the window after the previous branch.
        // You can come back and add a window after it has passed.
        // However, usually you wouldn't want to do this as it would throw away a lot of history.
        uint256 window = branches[parent_branch_hash].window + 1;

        require(window % (4 * 6) == 0 || window == 6);

        branches[branch_hash] = Branch(parent_branch_hash, whitelist_id, now, window);
        window_branches[window].push(branch_hash);


        //Balance changes
        for(uint i=0;i<forkonomicToken.length;i++){
            if(compensationForBlanceChange[i] > 0 && balanceChange[i] > 0){
                branches[branch_hash].balance_change[keccak256(msg.sender, NULL_HASH)] += compensationForBlanceChange[i];
                //forkonomicToken[i].transferFrom(msg.sender, this, uint(balanceChange[i]), branch_hash);
            }
             if(compensationForBlanceChange[i] < 0 && balanceChange[i] < 0){
                require(!_isAmountSpendable(keccak256(msg.sender, NULL_HASH), uint(-compensationForBlanceChange), branch_hash)); // can only spend what you have
                branches[branch_hash].balance_change[keccak256(msg.sender, NULL_HASH)] -= -compensationForBlanceChange[i];
                //forkonomicToken[i].transfer(msg.sender, uint(-balanceChange[i]), branch_hash);
            }
        }

        emit BranchCreated(branch_hash,whitelist_id);
        return branch_hash;
    }

    function getWindowBranches(uint256 window)
    public constant returns (bytes32[]) {
        return window_branches[window];
    }

    function approve(address _spender, uint256 _amount, bytes32 _branch)
    public returns (bool success) {
        allowed[msg.sender][_spender][_branch] = _amount;
        emit Approval(msg.sender, _spender, _amount, _branch);
        return true;
    }

    function allowance(address _owner, address _spender, bytes32 branch)
    constant public returns (uint remaining) {
        return allowed[_owner][_spender][branch];
    }

    function balanceOf(address addr, bytes32 branch)
    public constant returns (uint256) {
        return balanceOfBox(addr, branch, NULL_HASH);
    }

    function balanceOfBox(address addr, bytes32 branch, bytes32 acct)
    public constant returns (uint256) {
        int256 bal = 0;
        while(branch != NULL_HASH) {
            bal += branches[branch].balance_change[keccak256(addr, acct)];
            branch = branches[branch].parent_hash;
        }
        return uint256(bal);
    }

    // Crawl up towards the root of the tree until we get enough, or return false if we never do.
    // You never have negative total balance above you, so if you have enough credit at any point then return.
    // This uses less gas than balanceOfAbove, which always has to go all the way to the root.
    function _isAmountSpendable(bytes32 acct, uint256 _min_balance, bytes32 branch_hash)
    internal constant returns (bool) {
        require (_min_balance <= 2100000000000000);
        int256 bal = 0;
        int256 min_balance = int256(_min_balance);
        while(branch_hash != NULL_HASH) {
            bal += branches[branch_hash].balance_change[acct];
            branch_hash = branches[branch_hash].parent_hash;
            if (bal >= min_balance) {
                return true;
            }
        }
        return false;
    }

    function isAmountSpendable(address addr, uint256 _min_balance, bytes32 branch_hash)
    public constant returns (bool) {
        return _isAmountSpendable(keccak256(addr, NULL_HASH), _min_balance, branch_hash);
    }

    function isBoxAmountSpendable(address addr, uint256 _min_balance, bytes32 branch_hash, bytes32 box)
    public constant returns (bool) {
        return _isAmountSpendable(keccak256(addr, box), _min_balance, branch_hash);
    }

    function boxTransferFrom(address from_addr, address to_addr, uint256 amount, bytes32 branch, bytes32 from_box, bytes32 to_box)
    public returns (bool) {

        require(allowed[from_addr][msg.sender][branch] >= amount);

        uint256 branch_window = branches[branch].window;

        require(amount <= 2100000000000000);
        require(branches[branch].timestamp > 0); // branch must exist

        if (branch_window < last_debit_windows[keccak256(from_addr, NULL_HASH)]) return false; // debits can't go backwards
        if (!_isAmountSpendable(keccak256(from_addr, from_box), amount, branch)) return false; // can only spend what you have

        last_debit_windows[keccak256(from_addr, NULL_HASH)] = branch_window;
        branches[branch].balance_change[keccak256(from_addr, from_box)] -= int256(amount);
        branches[branch].balance_change[keccak256(to_addr, to_box)] += int256(amount);

        uint256 allowed_before = allowed[from_addr][msg.sender][branch];
        uint256 allowed_after = allowed_before - amount;
        assert(allowed_before > allowed_after);

        emit Transfer(from_addr, to_addr, NULL_HASH, NULL_HASH, amount, branch);

        return true;
    }

    function recordBoxWithdrawal(bytes32 box, uint256 amount, bytes32 branch) {
        require(branches[branch].timestamp > 0); // branch must exist
        branches[branch].withdrawal_record[keccak256(msg.sender, box)] += int256(amount);
    }

    function hasBoxWithdrawal(address owner, bytes32 box, bytes32 branch_hash, bytes32 earliest_possible_branch)
    public view returns (bool) {
        bytes32 id = keccak256(owner, box);
        while(branch_hash != NULL_HASH && branch_hash != earliest_possible_branch) {
            if (branches[branch_hash].withdrawal_record[id]) {
                return true;
            }
            branch_hash = branches[branch_hash].parent_hash;
        }
        return false;
    }

    function recordedBoxWithdrawalAmount(address owner, bytes32 box, bytes32 branch_hash, bytes32 earliest_possible_branch, uint _min_balance) 
    public view returns (uint256) {
        bytes32 id = keccak256(owner, box);
        int256 bal = 0;
        int256 min_balance = int256(_min_balance);
        while(branch_hash != NULL_HASH && branch_hash != earliest_possible_branch) {
            bal += branches[branch_hash].withdrawal_record[id];
            branch_hash = branches[branch_hash].parent_hash;
        }
        return uint256(bal);
    }

    function transfer(address addr, uint256 amount, bytes32 branch)
    public returns (bool) {
        return boxTransfer(addr, amount, branch, NULL_HASH, NULL_HASH);
    }

    function transferFrom(address from, address addr, uint256 amount, bytes32 branch)
    public returns (bool) {
        return boxTransferFrom(from, addr, amount, branch, NULL_HASH, NULL_HASH);
    }

    function boxTransfer(address addr, uint256 amount, bytes32 branch, bytes32 from_box, bytes32 to_box)
    public returns (bool) {
        uint256 branch_window = branches[branch].window;

        require(amount <= 2100000000000000);
        require(branches[branch].timestamp > 0); // branch must exist

        if (branch_window < last_debit_windows[keccak256(msg.sender, from_box)]) return false; // debits can't go backwards
        if (!_isAmountSpendable(keccak256(msg.sender, from_box), amount, branch)) return false; // can only spend what you have

        last_debit_windows[keccak256(msg.sender, from_box)] = branch_window;
        branches[branch].balance_change[keccak256(msg.sender, from_box)] -= int256(amount);
        branches[branch].balance_change[keccak256(addr, to_box)] += int256(amount);

        emit Transfer(msg.sender, addr, from_box, to_box, amount, branch);

        return true;
    }

    function getParentHash(bytes32 hash)
    public returns (bytes32){
        return branches[hash].parent_hash;
    }

    function getTimestampOfBranch(bytes32 hash)
    public returns (uint256){
        return branches[hash].timestamp;
    }

    function boxTransferFrom(address addr, uint256 amount, bytes32 branch, bytes32 from_box)
    public returns (bool) {
        return boxTransferFrom(addr, amount, branch, from_box, NULL_HASH);
    }

    function getDataContract(bytes32 _branch)
    public constant returns (address) {
        return branches[_branch].data_cntrct;
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
