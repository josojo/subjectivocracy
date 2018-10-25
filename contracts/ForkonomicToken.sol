pragma solidity ^0.4.22;
import "./ForkonomicSystem.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract ForkonomicToken {
    using SafeMath for uint256;

    event Approval(address indexed _owner, bytes32 ownerBox, address indexed _spender,
        bytes32 spenderBox, uint _value, bytes32 branch);

    event Transfer(address indexed from,
        address to,
        bytes32 fromBox,
        bytes32 toBox,
        uint value,
        bytes32 branch);

    string public constant name = "RealityToken";
    string public constant symbol = "RLT";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    
    bytes32 constant NULL_HASH = "";

    // users balance changes are stored in the following mapping
    mapping(bytes32 => mapping(bytes32 => int256)) balanceChange; // user-account debits and credits

    // withdraws of tokens from other smart contracts can be stored here
    mapping(bytes32 => mapping(bytes32 => int256)) withdrawalRecord;

    // Spends, which may cause debits, can only go forwards.
    // That way when we check if you have enough to spend we only have to go backwards.
    mapping(bytes32 => uint256) public lastDebitWindows; // index of last user debits to stop you going backwards

    // allowances, as we have them in the ERC20 protocol 
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32=> uint256))) public allowed;

    uint256 public totalSupply;
    ForkonomicSystem public fSystem;

    constructor(ForkonomicSystem _fSystem, address[] initalFundingContracts)
    public {

        fSystem = _fSystem;
        bytes32 genesisBranchHash = fSystem.genesisBranchHash();
        uint256 numFunded = initalFundingContracts.length;

        require(numFunded < 12, " too many funding accounts");

        for (uint256 i=0; i < numFunded; i++) {
            bytes32 account = keccak256(abi.encodePacked(initalFundingContracts[i], NULL_HASH));
            balanceChange[genesisBranchHash][account] += 210000000000000;
            totalSupply += 210000000000000;
        }
    }

    function approve(address _spender, uint256 _amount, bytes32 _branch)
    public returns (bool success) {
        return approveBox(_spender, _amount, _branch, NULL_HASH, NULL_HASH);
    }

    function allowance(address owner, address spender, bytes32 branch)
    public constant returns (uint remaining) {
        return allowanceBox(owner, spender, branch, NULL_HASH, NULL_HASH);
    }

    function approveBox(address _spender, uint256 _amount, bytes32 _branch, bytes32 fromBox, bytes32 spenderBox)
    public returns (bool success) {
        bytes32 boxSpender = keccak256(abi.encodePacked(_spender, spenderBox));
        bytes32 boxFrom = keccak256(abi.encodePacked(msg.sender, fromBox));
        allowed[boxFrom][boxSpender][_branch] = _amount;
        emit Approval(msg.sender, fromBox, _spender, spenderBox, _amount, _branch);
        return true;
    }

    function allowanceBox(address owner, address spender, bytes32 branch, bytes32 senderBox, bytes32 receiverBox)
    public constant returns (uint remaining) {

        bytes32 spenderAccount = keccak256(abi.encodePacked(spender, senderBox));
        bytes32 ownerAccount = keccak256(abi.encodePacked(owner, receiverBox));
        return allowed[ownerAccount][spenderAccount][branch];
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
            branch = fSystem.branchParentHash(branch);
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
        uint256 branchWindow = fSystem.branchWindow(branch);

        require(amount <= 2100000000000000, " sending amount bigger than totalSupply");
        require(fSystem.doesBranchExist(branch), " branch must exist"); 
        bytes32 account =keccak256(abi.encodePacked(msg.sender, fromBox));
        require(branchWindow >= lastDebitWindows[account], " branchWindow >= lastDebitWindows[account]");  // debits can't go backwards
        require(_isAmountSpendable((account), amount, branch), " amount was not spendable");  // can only spend what you have

        lastDebitWindows[account] = branchWindow;
        balanceChange[branch][account] -= int256(amount);
        balanceChange[branch][keccak256(abi.encodePacked(addr, toBox))] += int256(amount);

        emit Transfer(addr, msg.sender, fromBox, toBox, amount, branch);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount, bytes32 branch)
    public returns (bool) {
        return boxTransferFrom(from, to, amount, branch, NULL_HASH, NULL_HASH);
    }

    function boxTransferFrom(address fromAddr, address toAddr, uint256 amount,
        bytes32 branch, bytes32 fromBox, bytes32 toBox)
    public returns (bool) {

        bytes32 boxFrom =keccak256(abi.encodePacked(fromAddr, fromBox));
        bytes32 boxTo = keccak256(abi.encodePacked(toAddr, toBox));
        bytes32 boxSender = keccak256(abi.encodePacked(msg.sender, toBox));
        require(allowed[boxFrom][boxSender][branch] >= amount);

        uint256 branchWindow = fSystem.branchWindow(branch);

        require(amount <= 2100000000000000, " amount higher than totalSupply");
        require(fSystem.doesBranchExist(branch), "branch must exist"); // branch must exist
        require(branchWindow >= lastDebitWindows[boxFrom], "debits cant go backwards");  // debits can't go backwards
        require(_isAmountSpendable((boxFrom), amount, branch), "amount must be spendable");  // can only spend what you have

        lastDebitWindows[boxFrom] = branchWindow;
        balanceChange[branch][boxFrom] -= int256(amount);
        balanceChange[branch][boxTo] += int256(amount);

        allowed[boxFrom][boxSender][branch] = allowed[boxFrom][boxSender][branch].sub(amount);

        emit Transfer(fromAddr, toAddr, NULL_HASH, NULL_HASH, amount, branch);

        return true;
    }

    function boxTransferFrom(address addr, address addrTo, uint256 amount, bytes32 branch, bytes32 fromBox)
    public returns (bool) {
        return boxTransferFrom(addr, addrTo, amount, branch, fromBox, NULL_HASH);
    }

    // record any withdrawal on a certain branch 
    function recordBoxWithdrawal(bytes32 box, uint256 amount, bytes32 branch) public returns (bool) {
        require(fSystem.branchTimestamp(branch) > 0); // branch must exist
        withdrawalRecord[branch][keccak256(abi.encodePacked(msg.sender, box))] += int256(amount);
        return true;
    }

    // check whether a withdrawal has already happend
    function hasBoxWithdrawal(address owner, bytes32 box, bytes32 branchHash, bytes32 earliestPossibleBranch) 
    public view returns (bool) {
        bytes32 id = keccak256(abi.encodePacked(owner, box));
        while (branchHash != NULL_HASH && branchHash != earliestPossibleBranch) {
            if (withdrawalRecord[branchHash][id] > 0) {
                return true;
            }
            branchHash = fSystem.branchParentHash(branchHash);
        }
        return false;
    }

    // check the sum of all withdrawals
    function recordedBoxWithdrawalAmount(address owner, bytes32 box,
        bytes32 branchHash, bytes32 earliestPossibleBranch) 
    public view returns (uint256) {
        bytes32 id = keccak256(abi.encodePacked(owner, box));
        int256 bal = 0;
        while (branchHash != NULL_HASH && branchHash != earliestPossibleBranch) {
            bal += withdrawalRecord[branchHash][id];
            branchHash = fSystem.branchParentHash(branchHash);
        }
        require(branchHash != NULL_HASH);
        return uint256(bal);
    }

    // Crawl up towards the root of the tree until we get enough, or return false if we never do.
    // You never have negative total balance above you, so if you have enough credit at any point then return.
    // This uses less gas than balanceOfAbove, which always has to go all the way to the root.
    function _isAmountSpendable(bytes32 acct, uint256 minBalance, bytes32 branchHash)
    public constant returns (bool) {
        require(minBalance <= 2100000000000000, "amount bigger than totalSupply");
        int256 bal = 0;
        int256 iminBalance = int256(minBalance);
        while (branchHash != NULL_HASH) {
            bal += balanceChange[branchHash][acct];
            branchHash = fSystem.branchParentHash(branchHash);
            if (bal >= iminBalance) {
                return true;
            }
        }
        return false;
    }

}
