pragma solidity ^0.4.22;
import "./ForkonomicSystem.sol";


contract ForkonomicToken {


    event Approval(address indexed _owner, address indexed _spender, uint _value, bytes32 branch);

    event Transfer(address indexed from,
        address indexed to,
        bytes32 fromBox,
        bytes32 toBox,
        uint value,
        bytes32 branch);

    string public constant name = "RealityToken";
    string public constant symbol = "RLT";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    
    bytes32 constant NULL_HASH = "";
    address constant NULL_ADDRESS = 0x0;

    // users balance changes are stored in the following mapping
    mapping(bytes32 => mapping(bytes32 => int256)) balanceChange; // user-account debits and credits

    // withdraws of tokens from other smart contracts can be stored here
    mapping(bytes32 => mapping(bytes32 => int256)) withdrawalRecord;

    // Spends, which may cause debits, can only go forwards.
    // That way when we check if you have enough to spend we only have to go backwards.
    mapping(bytes32 => uint256) public lastDebitWindows; // index of last user debits to stop you going backwards

    // allowances, as we have them in the ERC20 protocol 
    mapping(address => mapping(address => mapping(bytes32=> uint256))) allowed;

    uint256 public totalSupply;


    ForkonomicSystem public fSystem;

    constructor(ForkonomicSystem _fSystem, address[] initalFundingContracts)
    public {

        fSystem = _fSystem;
        bytes32 genesisMerkleRoot = keccak256("I leave to several futures (not to all) my garden of forking paths");
        bytes32 genesisBranchHash = keccak256(abi.encodePacked(NULL_HASH, genesisMerkleRoot, NULL_ADDRESS));
        uint256 num_funded = initalFundingContracts.length;

        require(num_funded < 11);

        for (uint256 i=0; i < num_funded; i++) {
            balanceChange[genesisBranchHash][keccak256(abi.encodePacked(initalFundingContracts[i], NULL_HASH))] = 210000000000000;
            totalSupply += 210000000000000;
        }
    }

    function approve(address _spender, uint256 _amount, bytes32 _branch)
    public returns (bool success) {
        allowed[msg.sender][_spender][_branch] = _amount;
        emit Approval(msg.sender, _spender, _amount, _branch);
        return true;
    }

    function allowance(address owner, address spender, bytes32 branch)
    public constant returns (uint remaining) {
        return allowed[owner][spender][branch];
    }

    function balanceOf(address addr, bytes32 branch)
    public constant returns (uint256) {
        return balanceOfBox(addr, branch, NULL_HASH);
    }

    function balanceOfBox(address addr, bytes32 branch, bytes32 acct)
    public constant returns (uint256) {
        int256 bal = 0;
        while (branch != NULL_HASH) {
            bal += balanceChange[branch][keccak256(abi.encodePacked(addr, acct))];
            branch = fSystem.getParentHash(branch);
        }
        return uint256(bal);
    }

    function isAmountSpendable(address addr, uint256 minBalance, bytes32 branchHash)
    public constant returns (bool) {
        return _isAmountSpendable(keccak256(abi.encodePacked(addr, NULL_HASH)), minBalance, branchHash);
    }

    function isAmountSpendableBox(address addr, uint256 minBalance, bytes32 branchHash, bytes32 box)
    public constant returns (bool) {
        return _isAmountSpendable(keccak256(abi.encodePacked(addr, box)), minBalance, branchHash);
    }

    function transfer(address addr, uint256 amount, bytes32 branch)
    public returns (bool) {
        return boxTransfer(addr, amount, branch, NULL_HASH, NULL_HASH);
    }

    function boxTransfer(address addr, uint256 amount, bytes32 branch, bytes32 fromBox, bytes32 toBox)
    public returns (bool) {
        uint256 branchWindow = fSystem.getWindowOfBranch(branch);

        require(amount <= 2100000000000000);
        require(fSystem.getTimestampOfBranch(branch) > 0); // branch must exist

        if (branchWindow < lastDebitWindows[keccak256(abi.encodePacked(msg.sender, fromBox))])
            return false; // debits can't go backwards
        if (!_isAmountSpendable(keccak256(abi.encodePacked(msg.sender, fromBox)), amount, branch)) 
            return false; // can only spend what you have

        lastDebitWindows[keccak256(abi.encodePacked(msg.sender, fromBox))] = branchWindow;
        balanceChange[branch][keccak256(abi.encodePacked(msg.sender, fromBox))] -= int256(amount);
        balanceChange[branch][keccak256(abi.encodePacked(addr, toBox))] += int256(amount);

        emit Transfer(msg.sender, addr, fromBox, toBox, amount, branch);

        return true;
    }

    function transferFrom(address from, address addr, uint256 amount, bytes32 branch)
    public returns (bool) {
        return boxTransferFrom(from, addr, amount, branch, NULL_HASH, NULL_HASH);
    }

    function boxTransferFrom(address fromAddr, address toAddr, uint256 amount, bytes32 branch, bytes32 fromBox, bytes32 toBox)
    public returns (bool) {

        require(allowed[fromAddr][msg.sender][branch] >= amount);

        uint256 branchWindow = fSystem.getWindowOfBranch(branch);

        require(amount <= 2100000000000000);
        require(fSystem.getTimestampOfBranch(branch) > 0); // branch must exist

        if (branchWindow < lastDebitWindows[keccak256(abi.encodePacked(fromAddr, NULL_HASH))])
            return false; // debits can't go backwards
        if (!_isAmountSpendable(keccak256(abi.encodePacked(fromAddr, fromBox)), amount, branch))
            return false; // can only spend what you have

        lastDebitWindows[keccak256(abi.encodePacked(fromAddr, NULL_HASH))] = branchWindow;
        balanceChange[branch][keccak256(abi.encodePacked(fromAddr, fromBox))] -= int256(amount);
        balanceChange[branch][keccak256(abi.encodePacked(toAddr, toBox))] += int256(amount);

        uint256 allowedBefore = allowed[fromAddr][msg.sender][branch];
        uint256 allowedAfter = allowedBefore - amount;
        assert(allowedBefore > allowedAfter);

        emit Transfer(fromAddr, toAddr, NULL_HASH, NULL_HASH, amount, branch);

        return true;
    }

    function boxTransferFrom(address addr, address addrTo, uint256 amount, bytes32 branch, bytes32 fromBox)
    public returns (bool) {
        return boxTransferFrom(addr, addrTo, amount, branch, fromBox, NULL_HASH);
    }

    // record any withdrawal on a certain branch 
    function recordBoxWithdrawal(bytes32 box, uint256 amount, bytes32 branch) public {
        require(fSystem.getTimestampOfBranch(branch) > 0); // branch must exist
        withdrawalRecord[branch][keccak256(abi.encodePacked(msg.sender, box))] += int256(amount);
    }

    // check whether a withdrawal has already happend
    function hasBoxWithdrawal(address owner, bytes32 box, bytes32 branchHash, bytes32 earliestPossibleBranch) 
    public view returns (bool) {
        bytes32 id = keccak256(abi.encodePacked(owner, box));
        while (branchHash != NULL_HASH && branchHash != earliestPossibleBranch) {
            if (withdrawalRecord[branchHash][id] > 0) {
                return true;
            }
            branchHash = fSystem.getParentHash(branchHash);
        }
        return false;
    }

    // check the sum of all withdrawals
    function recordedBoxWithdrawalAmount(address owner, bytes32 box, bytes32 branchHash, bytes32 earliestPossibleBranch) 
    public view returns (uint256) {
        bytes32 id = keccak256(abi.encodePacked(owner, box));
        int256 bal = 0;
        while (branchHash != NULL_HASH && branchHash != earliestPossibleBranch) {
            bal += withdrawalRecord[branchHash][id];
            branchHash = fSystem.getParentHash(branchHash);
        }
        require(branchHash != NULL_HASH);
        return uint256(bal);
    }

    // Crawl up towards the root of the tree until we get enough, or return false if we never do.
    // You never have negative total balance above you, so if you have enough credit at any point then return.
    // This uses less gas than balanceOfAbove, which always has to go all the way to the root.
    function _isAmountSpendable(bytes32 acct, uint256 minBalance, bytes32 branchHash)
    public constant returns (bool) {
        require(minBalance <= 2100000000000000);
        int256 bal = 0;
        int256 iminBalance = int256(minBalance);
        while (branchHash != NULL_HASH) {
            bal += balanceChange[branchHash][acct];
            branchHash = fSystem.getParentHash(branchHash);
            if (bal >= iminBalance) {
                return true;
            }
        }
        return false;
    }
}
