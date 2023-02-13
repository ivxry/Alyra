// SPDX-License-Identifier: MIT

//pragma solidity latest; <- not working on remix
pragma solidity 0.8.18; 

//import ownership crontract from github
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    //must use struct
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    //must use struct
    struct Proposal {
        string description;
        uint voteCount;
    }

    //must use enum
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    //event to register new voter
    event VoterRegistered(address voterAddress);

    //event to change state
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus);

    //event to register proposal
    event ProposalRegistered(uint proposalId);

    //event to tell if a voter voted
    event Voted (address voter, uint proposalId);

    //owner makes whitelist
    mapping(address => Voter) voters;
    
    Proposal[] proposals;
    uint winningProposalId;
    WorkflowStatus  Status  = WorkflowStatus.RegisteringVoters;
    uint voteCounter;
    
    //registering voters OK + No Double Entry OK
    function registerVoter(address _voter) public onlyOwner {
        require(Status == WorkflowStatus.RegisteringVoters, "Sorry Not Registering Voters At The Moment");
        require(voters[_voter].isRegistered == false, "No On Chain Propaganda Sorry");
        voters[_voter].isRegistered  = true;
        emit VoterRegistered(_voter);
    }

    //start proposal registration OK
    function startProposalRegistration() public onlyOwner {
        require (Status == WorkflowStatus.RegisteringVoters, "Sorry Not Registering Proposals At The Moment");
        Status = WorkflowStatus.ProposalsRegistrationStarted;        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);        
    }

    //stop proposal registration OK
    function stopProposalRegistration() public onlyOwner {
        require (Status == WorkflowStatus.ProposalsRegistrationStarted, "Sorry Proposals Already Closed");
        Status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    //register proposal OK
    function registerProposal(string memory _description) public {
        require(Status == WorkflowStatus.ProposalsRegistrationStarted, "Sorry Not Registering Proposals At The Moment");
        proposals.push(Proposal(_description, 0));
        uint proposalId = proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }

    //start voting OK
    function startVotingSession() public onlyOwner {
        require(Status == WorkflowStatus.ProposalsRegistrationEnded, "Proposal Registration Still Open");
        Status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    //stop voting OK
    function endVotingSession() public onlyOwner {
        require(Status == WorkflowStatus.VotingSessionStarted, "Sorry Voting Session Closed");
        Status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    //register vote OK
    function vote(uint proposalId ) public {
        require(Status == WorkflowStatus.VotingSessionStarted, "Wait For The Session To Start");
        require(voters[msg.sender].isRegistered == true, "Not A Registered Voter");
        require(voters[msg.sender].hasVoted == false, "No On Chain Propaganda Sorry");
        require(proposalId < proposals.length, "Invalide Proposal");
        proposals[proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        emit Voted (msg.sender, proposalId);
    }



    //get winner 
    function getWinner() public onlyOwner {
        require(Status == WorkflowStatus.VotingSessionEnded, "Votes Still Open");
        Status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        uint winnerVotes = 0;
        for (uint v = 0; v < proposals.length; v++) {
            if (proposals[v].voteCount > winnerVotes) {
                winnerVotes = proposals[v].voteCount;
                winningProposalId = v;
            }
        }
    }
    function getWinningProposalId() public view returns (uint) {
    require(Status == WorkflowStatus.VotesTallied, "Votes Not Tallied");
    return winningProposalId;
    }

    //vote counter
    function getProposalVotePercentage(uint proposalId) public view returns (uint) {
        require(proposalId < proposals.length, "Invalid Proposal ID");
        uint totalVotes = 0;
        for (uint i = 0; i < proposals.length; i++) {
            totalVotes += proposals[i].voteCount;
        }
        return proposals[proposalId].voteCount / totalVotes * 100;
    }
}