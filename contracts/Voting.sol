// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
//import "@OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] proposals;

    // WorkflowStatus gère les différents états d’un vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }   

    WorkflowStatus currentWorkflowStatus;

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    mapping (address => Voter) whitelist;

    uint public winninProposalId;

    constructor() public {
        currentWorkflowStatus = WorkflowStatus.RegisteringVoters;
    }

    function getCurrentWFStatus() public view returns (WorkflowStatus) {
        return currentWorkflowStatus;
    }

    function registerVoter(address _voter) external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.RegisteringVoters);
        require(whitelist[_voter].isRegistered == false, "This voter is already registered !"); //require(whitelist[_voter] != undefined);
        whitelist[_voter] = Voter({isRegistered: true, hasVoted : false, votedProposalId:0}); 
        emit VoterRegistered(_voter);
    }

    function startProposalsRegistration() external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.RegisteringVoters);
        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }

    function registerProposal(string memory _description) external {
        require(whitelist[msg.sender].isRegistered == true, "You are not yet registered !");
        proposals.push(Proposal({description: _description, voteCount: 0}));
        emit ProposalRegistered(proposals.length-1);
    }

    function endProposalsRegistration() external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals registration is not yet started");
        require(proposals.length >= 1, "There is no proposal yet !");
        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }

    function startVotingSession() external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Proposal registration is not yet ended");
        currentWorkflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }

    function vote(uint _proposalId) external {
        require(whitelist[msg.sender].isRegistered == true, "You are not yet registered");
        require(whitelist[msg.sender].hasVoted == false, "You have already vote !");
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function stopVotingSession() external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session is not started !");
        currentWorkflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        emit VotingSessionStarted();
    }

    function tallyVotes() external returns (uint) {
        if (currentWorkflowStatus == WorkflowStatus.VotesTallied) {
            return winninProposalId;
        }

        require(proposals.length >= 1, "there is no proposal to vote !");
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionEnded, "Voting session is not yet ended !");
        uint _winninProposalId = 0;
        uint winninProposalVoteCount = proposals[0].voteCount;

        for (uint i=1; i < proposals.length; i++) {
            if (proposals[i].voteCount > winninProposalVoteCount) {
                _winninProposalId = i;
                winninProposalVoteCount = proposals[i].voteCount;
            }
        }

        currentWorkflowStatus = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        emit VotesTallied();
        winninProposalId = _winninProposalId;
        return winninProposalId;
    }

}