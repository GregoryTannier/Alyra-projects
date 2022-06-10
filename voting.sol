// SPDX-Licence-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    uint winingProposalId;
    uint voteCount = 0;
    
    // l'admin (owner) est celui qui va déployer le SM (on n'a pas besoin de le définir car déjà présent dans le fichier "Ownable"
    /*

    constructor() {
        owner = msg.sender;
        
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    */

    event VoterRegistered(address voterAddress); // done
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId); // done
    event Voted (address voter, uint proposalId);

    /*
    constructor(string[] memory proposalDescription) {
        for (uint i = 0; i < proposalDescription.length; i++) {
            proposals.push(Proposal({
                description: proposalDescription[i],
                voteCount: 0
            }));
        }
    }
    */

    enum WorkflowStatus { 
        RegisteringVoters, 
        ProposalsRegistrationStarted, 
        ProposalsRegistrationEnded, 
        VotingSessionStarted, 
        VotingSessionEnded,
        VotesTallied
    }
    WorkflowStatus public state; // mon enum possède une variable qui s'appelle "state"

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }

    mapping (address => bool) public whitelisted;
    mapping(address => Voter) public voters;

    Proposal[] proposals;

    /*
    // 1- l'admin lance l'enregistrement des votants sur liste blanche // état = RegisteringVoters
    function startRegisteringVoters() public onlyOwner {
        state = WorkflowStatus.RegisteringVoters;
    } 
    */

    // 1bis- fonction enregistrement des adresses des votants = owner // whitelist // event VoterRegistered // OK
    function whitelist (address voterAddress) public onlyOwner {
        require(!whitelisted[voterAddress], "address is already whitelisted");
        whitelisted[voterAddress] = true;
        emit VoterRegistered(voterAddress);
    }

    // 2- fonction démarrer la session d'enregistrement des propositions = owner // état = ProposalsRegistrationStarted 
    function startRegistrationProposals () public onlyOwner {
        state = WorkflowStatus.ProposalsRegistrationStarted;
    }

    // 3- fonction ajouter une proposition = ALL // require = ProposalsRegistrationStarted // event ProposalRegistered
    function addProposal (string memory description, uint proposalId, address voterAddress) public {
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration session is not yet started");
        require(whitelisted[voterAddress] = true, "You must be registered to submit a proposal");
        proposals.push(Proposal(description, proposalId));
        emit ProposalRegistered(proposalId);
    }

    // 4- fonction arrêter l'enregistrement des propositions = owner // require = ProposalsRegistrationStarted // état = ProposalsRegistrationEnded
    function endRegistrationProposals () public onlyOwner {
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "You want to stop the proposal registration session whereas it is not yet started");
        state = WorkflowStatus.ProposalsRegistrationEnded;
    }
    
    // 5- fonction démarrer la session de vote = owner // require = ProposalsRegistrationEnded // état = VotingSessionStarted
    function startVotingSession () public onlyOwner {
        require(state == WorkflowStatus.ProposalsRegistrationEnded, "You must end the proposal registration session before to start voting session");
        state = WorkflowStatus.VotingSessionStarted;
    }

    // 6- fonction visualiser la liste des proposition = ALL // require = VotingSessionStarted
    function getProposals() public view returns (Proposal[] memory){
        require(state == WorkflowStatus.VotingSessionStarted, "You can not see proposals because voting session is not yet started");
        return proposals;
    }

    // 7- fonction voter pour la proposition préférée = ALL // require = VotingSessionStarted // event Voted 
    function vote(uint proposalId) public {
        Voter memory sender = voters[msg.sender];
        require(!sender.hasVoted, "Already voted.");
        require(proposalId<proposals.length, "This proposal is not in the list");
        sender.hasVoted = true;
        sender.votedProposalId = proposalId;
        // emit Voted (voter, proposalId);
    }

    // 8- fonction arrêter la session de vote = owner // require = VotingSessionStarted // état = VotingSessionEnded
    function endVotingSession () public onlyOwner {
        require(state == WorkflowStatus.VotingSessionStarted, "You want to end voting session whereas it is not yet started");
        state = WorkflowStatus.VotingSessionEnded;
        state = WorkflowStatus.VotesTallied;
    }
    /*
    // 9- fonction comptabiliser les votes = owner // uint voteCount // require = VotingSessionEnded // état = VotesTallied
    // A TERMINER
    function countVotes (uint voteCount) public onlyOwner {
        require(state == WorkflowStatus.VotingSessionEnded, "You must end voting session before to count votes");
        voteCount++;
        state = WorkflowStatus.VotesTallied;
    }
    */

    // 10- fonction annoncer l'id gagnant = require = VotesTallied
    function getWinningProposalId() public view returns (uint winningProposalId) {
        require (state == WorkflowStatus.VotingSessionEnded);
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalId = p;
            }
        }
    }
    
    // 11- fonction hasVoted
    function hasVoted (address voterAddress) public view returns (bool) {
        return whitelisted[voterAddress];
    }
}