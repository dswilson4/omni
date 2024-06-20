// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.24;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Governance is OwnableUpgradeable {
    event SubmitProposal(uint256 indexed proposalId, address indexed proposer, string description);
    event Vote(uint256 indexed proposalId, address indexed voter, bool support);
    event Deposit(uint256 indexed proposalId, address indexed depositor, uint256 amount);

    uint256 public proposalCount;
    mapping(uint256 => string) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes;
    mapping(uint256 => uint256) public deposits;

    function submitProposal(string calldata description) external {
        proposalCount++;
        proposals[proposalCount] = description;
        emit SubmitProposal(proposalCount, msg.sender, description);
    }
    function vote(uint256 proposalId, bool support) external {
        require(bytes(proposals[proposalId]).length > 0, "Governance: proposal does not exist");
        votes[proposalId][msg.sender] = support;
        emit Vote(proposalId, msg.sender, support);
    }
    function deposit(uint256 proposalId) external payable {
        require(bytes(proposals[proposalId]).length > 0, "Governance: proposal does not exist");
        deposits[proposalId] += msg.value;
        emit Deposit(proposalId, msg.sender, msg.value);
    }
}