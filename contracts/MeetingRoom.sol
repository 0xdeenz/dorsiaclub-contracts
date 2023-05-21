// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBusinessCard.sol";
import "./interfaces/IMeetingRoom.sol";
import "./libs/CardMaestro.sol";

contract MeetingRoom is IMeetingRoom, Ownable {
    using CardMaestro for uint256;

    /// Business Card smart contract
    IBusinessCard immutable businessCardContract;

    /// Total number of meeting rooms that have been created
    uint256 public totalMeetingRooms;

    /// @dev Gets a meeting room ID and returns the corresponding `Meeting` struct
    mapping(uint256 => Meeting) private _meetingRooms;

    /// @dev Gets a meeting room ID and an address and returns its card commitment.
    mapping(uint256 => mapping(address => uint256)) private _cardCommitments;

    /// @dev Initializes the Meeting Room smart contract
    constructor(address businessCard) {
        businessCardContract = IBusinessCard(businessCard);
    }

    /// @dev See {IMeetingRoom-createMeetingRoom}
    function createMeetingRoom(uint256 cardCommitment, uint256 timeToMeetingStart, uint256 meetingDuration) external payable override {
        if (msg.value == 0) { revert InvalidBetAmount(); }

        if (
            timeToMeetingStart < MINIMUM_TIME_TO_MEETING_START || timeToMeetingStart > MAXIMUM_TIME_TO_MEETING_START
        ) { revert InvalidTimeToMeetingStart(); }
        if (
            meetingDuration < MINIMUM_MEETING_DURATION || meetingDuration > MAXIMUM_MEETING_DURATION
        ) { revert InvalidMeetingDuration(); }

        totalMeetingRooms++;

        _cardCommitments[totalMeetingRooms][_msgSender()] = cardCommitment;

        uint256 startTime = block.timestamp + timeToMeetingStart * 1 minutes;
        uint256 endTime = block.timestamp + timeToMeetingStart * 1 minutes + meetingDuration * 1 minutes;

        _meetingRooms[totalMeetingRooms].meetingStart = startTime;
        _meetingRooms[totalMeetingRooms].meetingEnd = endTime;
        _meetingRooms[totalMeetingRooms].betAmount = msg.value;
        _meetingRooms[totalMeetingRooms].participants++;

        emit MeetingRoomCreated(totalMeetingRooms, msg.value, startTime, endTime, cardCommitment, _msgSender());
    }

    /// @dev See {IMeetingRoom-joinMeetingRoom}
    function joinMeetingRoom(uint256 roomId, uint256 cardCommitment) external payable override {
        if (block.timestamp > _meetingRooms[roomId].meetingStart) { revert MeetingOngoing(); }
        if (msg.value != _meetingRooms[roomId].betAmount) { revert InvalidBetAmount(); }
        if (_meetingRooms[roomId].participants == MAXIMUM_MEETING_PARTICIPANTS) { revert MeetingFull(); }

        _cardCommitments[roomId][_msgSender()] = cardCommitment;

        _meetingRooms[roomId].participants++;

        emit MeetingRoomJoined(roomId, cardCommitment, _msgSender());
    }

    /// @dev See {IMeetingRoom-revealCard}
    function revealCard(uint256 roomId, uint256 cardCommitment, uint256 cardId, uint256 salt) external override {
        if (_cardCommitments[roomId][_msgSender()] != cardCommitment) { revert CardCommitmentDoesNotMatch(); }
        if (cardCommitment != uint256(keccak256(abi.encodePacked(cardId, salt)))) { revert RevealedCardDoesNotMatch(); }
        if (businessCardContract.ownerOf(cardId) != _msgSender()) { revert CallerDoesNotOwnCard(); }

        uint nRevealed = _meetingRooms[roomId].cardIds.length;

        if (nRevealed == 0) {  // first reveal
            _meetingRooms[roomId].cardIds.push(cardId);
            _meetingRooms[roomId].winningChances.push(1);
        } else {
            uint256 winningChance = 1; 

            for (uint256 i; i < nRevealed; ) {
                uint256 rivalCardId = _meetingRooms[roomId].cardIds[i];

                if (rivalCardId == cardId) { revert CardAlreadyRevealed(); }

                uint256 chanceAgainst = businessCardContract.getCardGenes(cardId).getWinningChanceAgainst(
                    businessCardContract.getCardGenes(rivalCardId)
                );

                _meetingRooms[roomId].winningChances[i] *= (PRECISION - chanceAgainst) / PRECISION;
                winningChance *= chanceAgainst / PRECISION;
                
                unchecked {
                    i++;
                }
            }

            _meetingRooms[roomId].cardIds.push(cardId);
            _meetingRooms[roomId].winningChances.push(winningChance);
        }

        emit CardRevealed(roomId, cardCommitment, cardId);
    }

    /// @dev See {IMeetingRoom-finishMeeting}
    function finishMeeting(uint256 roomId) external override {
        if (block.timestamp < _meetingRooms[roomId].meetingEnd) { revert MeetingOngoing(); }
        if (_meetingRooms[roomId].winner != address(0)) { revert MeetingFinished(); }

        uint nRevealed = _meetingRooms[roomId].cardIds.length;

        if (nRevealed == 0) {
            // No one revealed their cards in time and thus no winner can be drawn, the funds get locked inside the smart contract
            _meetingRooms[roomId].winner = address(this);

            emit WinnerDrawn(roomId, address(this));
        } else {
            uint256 scale;

            for (uint256 i; i < nRevealed; ) {
                scale += _meetingRooms[roomId].winningChances[i];

                unchecked {
                    i++;
                }
            }
            
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(
                block.timestamp + ((uint256(keccak256(abi.encodePacked(tx.gasprice)))) /
                (block.timestamp)) + ((uint256(keccak256(abi.encodePacked(tx.origin)))) /
                (block.timestamp)) + block.number + tx.gasprice
            ))) % PRECISION;

            uint256 chanceSum;

            for (uint256 i; i < nRevealed; ) {
                chanceSum += _meetingRooms[roomId].winningChances[i] * PRECISION / scale;

                if (randomNumber < chanceSum) {
                    _meetingRooms[roomId].winner = businessCardContract.ownerOf(_meetingRooms[roomId].cardIds[i]);
                    break;
                }

                unchecked {
                    i++;
                }
            }

            uint256 prize = _meetingRooms[roomId].betAmount * _meetingRooms[roomId].participants;
            (bool success, ) = payable(_meetingRooms[roomId].winner).call{ value: prize }("");

            if (!success) { revert(); }

            emit WinnerDrawn(roomId, _meetingRooms[roomId].winner);
        }
    }

    /// @dev See {IMeetingRoom-withdraw}
    function withdraw() external override onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{ value: balance }("");

        if (!success) { revert(); }
    }

    /// @dev See {IMeetingRoom-getMeetingRoom}
    function getMeetingRoom(uint256 roomId) external view override returns (Meeting memory) {
        return _meetingRooms[roomId];
    }
}
