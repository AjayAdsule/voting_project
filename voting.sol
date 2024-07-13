// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract Vote {
    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        Gender gender;
        uint256 voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint256 age;
        Gender gender;
        uint256 candidateId;
        address candidateAddress;
        uint256 votes;
    }

    address electionCommission;
    address public winner;
    uint256 nextVoterId = 1;
    uint256 nextCandidateId = 1;
    uint256 startTime;
    uint256 endTime;
    bool stopVoting;

    constructor() {
        electionCommission = msg.sender;
    }

    mapping(uint256 => Voter) voterDetails;
    mapping(uint256 => Candidate) candidateDetails;

    enum VotingStatus {
        NotStarted,
        InProgress,
        Ended
    }
    enum Gender {
        NotSpecified,
        Male,
        Female,
        Other
    }

    modifier isVotingOver() {
        require(endTime >= block.timestamp, "voting is over");
        _;
    }

    modifier onlyCommissioner() {
        require(
            msg.sender == electionCommission,
            "you are not allowed to perform this opretion"
        );
        _;
    }

    modifier isValidAge(uint256 _age) {
        require(_age < 18, "age is not valid");
        _;
    }

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) external isValidAge(_age) {
        require(
            isCandidateNotRegistered(msg.sender),
            "candidate is already registered"
        );
        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            gender: _gender,
            age: _age,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
        });
        nextCandidateId++;
    }

    function isCandidateNotRegistered(address _person)
        private
        view
        returns (bool)
    {
        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function getCandidateList() public view returns (Candidate[] memory) {
        //whole mapping is not return with fuction so we need to create array and store whole data in that array
        Candidate[] memory candidateList = new Candidate[](nextCandidateId - 1);
        for (uint256 i = 0; i < candidateList.length; i++) {
            candidateList[i] = candidateDetails[i + 1];
        }
        return candidateList;
    }

    function isVoterNotRegistered(address _person) private view returns (bool) {
        for (uint256 i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voterAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) external isValidAge(_age) {
        require(
            isVoterNotRegistered(msg.sender),
            "voter is already registered"
        );
        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            voterId: nextVoterId,
            gender: _gender,
            voteCandidateId: 0,
            voterAddress: msg.sender
        });
        nextVoterId++;
    }

    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](nextVoterId - 1);
        for (uint256 i = 0; i < voterList.length; i++) {
            voterList[i] = voterDetails[i + 1];
        }
        return voterList;
    }

    function castVote(uint256 _voterId, uint256 _candidataId) external {
        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "You are not authorized"
        );
        require(
            voterDetails[_voterId].voteCandidateId == 0,
            "you already cast vote"
        );
        voterDetails[_voterId].voteCandidateId = _candidataId;
        candidateDetails[_candidataId].votes++;
    }

    function setVotingPeriod(uint256 _startTime, uint256 _endTime)
        external
        onlyCommissioner
    {
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted;
        } else if (endTime >= block.timestamp && stopVoting == true) {
            return VotingStatus.Ended;
        } else {
            return VotingStatus.InProgress;
        }
    }

    function announceVotingResult() external onlyCommissioner {
        uint256 maximumCount;
        address winnerAddress;
        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maximumCount) {
                maximumCount = candidateDetails[i].votes;
                winnerAddress = candidateDetails[i].candidateAddress;
            }
        }
        winner = winnerAddress;
    }

    function emergencyStopVoting() public onlyCommissioner {
        stopVoting = true;
    }
}
