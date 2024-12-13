// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./SafeMath.sol"; // Import SafeMath library

contract Sportcrypto {
    // Mapping to store token balances of each address
    mapping(address => uint) public balances;
    // Mapping to store allowances for delegated spending
    mapping(address => mapping(address => uint)) public allowance;

    // Token properties
    uint256 public totalSupply = 1000000*10**18; // 1,000,000 tokens * 10^18 (Wei per token)
    string public name = "SportCrypto"; // Token name
    string public symbol = "SP"; // Token symbol
    uint8 public decimals = 18; // Token decimal places

    // Governance-related variables
    struct Proposal {
        string description; // Description of the proposal
        uint voteCount; // Total votes received
        bool executed; // Status of proposal execution
    }

    // Array to store all proposals
    Proposal[] public proposals;
    // Mapping to track whether an address has voted on a proposal
    mapping(uint => mapping(address => bool)) public voted;
    // Address of the contract owner
    address public contractOwner;

    // Events for transparency
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event ProposalCreated(uint proposalId, string description);
    event VoteCasted(address voter, uint proposalId);
    event ProposalExecuted(uint proposalId, string description);

    // Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner can call this function");
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply; // Assign all tokens to the deployer
        contractOwner = msg.sender; // Set the deployer as the owner
    }

    // Function to get the balance of a specific address
    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    // Function to transfer tokens to another address
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        require(balances[to] + value <= totalSupply / 10, "Exceeds max ownership cap");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Function to transfer tokens on behalf of another address
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        require(balances[to] + value <= totalSupply / 10, "Exceeds max ownership cap");

        allowance[from][msg.sender] -= value;
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    // Function to approve an allowance for another address
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Governance functions

    // Function to create a new proposal
    function createProposal(string memory description) public {
        require(bytes(description).length > 0, "Description cannot be empty");
        proposals.push(Proposal({
            description: description,
            voteCount: 0,
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, description);
    }

    // Function to cast a vote on a proposal
    function vote(uint proposalId) public {
        require(proposalId < proposals.length, "Invalid proposal ID");
        require(!voted[proposalId][msg.sender], "Already voted");
        require(balanceOf(msg.sender) > 0, "Must own SP to vote");

        proposals[proposalId].voteCount += balanceOf(msg.sender); // Vote weight based on token balance
        voted[proposalId][msg.sender] = true;

        emit VoteCasted(msg.sender, proposalId);
    }

    // Function to execute a proposal
    function executeProposal(uint proposalId) public onlyOwner {
        require(proposalId < proposals.length, "Invalid proposal ID");
        require(!proposals[proposalId].executed, "Proposal already executed");

        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId, proposals[proposalId].description);
    }

    // Function to retrieve all proposals
    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}
