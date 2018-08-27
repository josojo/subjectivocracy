pragma solidity ^0.4.18;

contract ForkonomicsInterface{

    event Approval(address indexed _owner, address indexed _spender, uint _value, bytes32 branch);
    event Transfer(address indexed _from, address indexed _to, bytes32 _from_box, bytes32 _to_box, uint _value, bytes32 branch);
   
    string public constant name = "RealityToken";
    string public constant symbol = "RLT";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    



    function approve(address _spender, uint256 _amount, bytes32 _branch)
    public returns (bool success);

    function allowance(address _owner, address _spender, bytes32 branch)
    constant public returns (uint remaining);

    function balanceOf(address addr, bytes32 branch)
    public constant returns (uint256);
    function balanceOfBox(address addr, bytes32 branch, bytes32 acct)
    public constant returns (uint256);

    // Crawl up towards the root of the tree until we get enough, or return false if we never do.
    // You never have negative total balance above you, so if you have enough credit at any point then return.
    // This uses less gas than balanceOfAbove, which always has to go all the way to the root.
    function _isAmountSpendable(bytes32 acct, uint256 _min_balance, bytes32 branch_hash)
    internal constant returns (bool);

    function isAmountSpendable(address addr, uint256 _min_balance, bytes32 branch_hash)
    public constant returns (bool);

    function isBoxAmountSpendable(address addr, uint256 _min_balance, bytes32 branch_hash, bytes32 box)
    public constant returns (bool);

    function boxTransferFrom(address from_addr, address to_addr, uint256 amount, bytes32 branch, bytes32 from_box, bytes32 to_box)
    public returns (bool);

    function recordBoxWithdrawal(bytes32 box, uint256 amount, bytes32 branch);

    function hasBoxWithdrawal(address owner, bytes32 box, bytes32 branch_hash, bytes32 earliest_possible_branch) 
    public view returns (bool);

    function recordedBoxWithdrawalAmount(address owner, bytes32 box, bytes32 branch_hash, bytes32 earliest_possible_branch) 
    public view returns (uint256);

    function transfer(address addr, uint256 amount, bytes32 branch)
    public returns (bool);
    function transferFrom(address from, address addr, uint256 amount, bytes32 branch)
    public returns (bool);

    function boxTransfer(address addr, uint256 amount, bytes32 branch, bytes32 from_box, bytes32 to_box)
    public returns (bool);

    function boxTransferFrom(address addr, address addr_to, uint256 amount, bytes32 branch, bytes32 from_box)
    public returns (bool);

}
