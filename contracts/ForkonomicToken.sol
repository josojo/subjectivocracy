pragma solidity ^0.4.18;
import "./RealityFund.sol";

contract ForkonomicToken {

    event Approval(address indexed _owner, address indexed _spender, uint _value, bytes32 branch);
    event Transfer(address indexed _from, address indexed _to, bytes32 _from_box, bytes32 _to_box, uint _value, bytes32 branch);
    event BranchCreated(bytes32 hash, address data_cntrct);

    string public constant name = "RealityToken";
    string public constant symbol = "RLT";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    
    bytes32 constant NULL_HASH = "";
    address constant NULL_ADDRESS = 0x0;

    struct Branch {
        mapping(bytes32 => int256) balance_change; // user-account debits and credits
        mapping(bytes32 => int256) withdrawal_record;
    }
    mapping(bytes32 => Branch) public branches;


    // Spends, which may cause debits, can only go forwards.
    // That way when we check if you have enough to spend we only have to go backwards.
    mapping(bytes32 => uint256) public last_debit_windows; // index of last user debits to stop you going backwards

    mapping(address => mapping(address => mapping(bytes32=> uint256))) allowed;
    RealityFund public realityContainer;

    constructor(RealityFund _realityContainer, address[] inital_funding_contracts)
    public {
        realityContainer = _realityContainer;
        bytes32 genesis_merkle_root = keccak256("I leave to several futures (not to all) my garden of forking paths");
        bytes32 genesis_branch_hash = keccak256(NULL_HASH, genesis_merkle_root, NULL_ADDRESS);
        branches[genesis_branch_hash] = Branch(NULL_HASH, genesis_merkle_root, NULL_ADDRESS, now, 0);

        uint256 i = 0;
        uint256 num_funded = inital_funding_contracts.length;
        require(num_funded < 11);
        for(i=0; i<inital_funding_contracts.length; i++) {
            branches[genesis_branch_hash].balance_change[keccak256(inital_funding_contracts[i], NULL_HASH)] = 210000000000000;
        }
    }


    function approve(address _spender, uint256 _amount, bytes32 _branch)
    public returns (bool success) {
        allowed[msg.sender][_spender][_branch] = _amount;
        Approval(msg.sender, _spender, _amount, _branch);
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
            branch = realityContainer.getParentHash(branch);
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
            branch_hash = realityContainer.getParentHash(branch_hash);
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
        require(realityContainer.getTimestampOfBranch(branch) > 0); // branch must exist
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

    function boxTransferFrom(address addr, uint256 amount, bytes32 branch, bytes32 from_box)
    public returns (bool) {
        return boxTransferFrom(addr, amount, branch, from_box, NULL_HASH);
    }

}