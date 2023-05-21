// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Meeting } from "../libs/Structs.sol";
import { 
    MAXIMUM_MEETING_PARTICIPANTS,
    MINIMUM_TIME_TO_MEETING_START,
    MAXIMUM_TIME_TO_MEETING_START,
    MINIMUM_MEETING_DURATION,
    MAXIMUM_MEETING_DURATION,
    PRECISION
} from "../libs/Constants.sol";

interface IMeetingRoom {
    error InvalidBetLimits();
    error InvalidBetAmount();
    error InvalidTimeToMeetingStart();
    error InvalidMeetingDuration();

    error MeetingOngoing();
    error MeetingFull();
    error MeetingFinished();

    error CardCommitmentDoesNotMatch();
    error CardAlreadyRevealed();
    error RevealedCardDoesNotMatch();
    error CallerDoesNotOwnCard();

    /// @dev Emitted when a Meeting Room gets created.
    /// @param roomId: ID of the Meeting Room that was created.
    /// @param bet: Bet necessary to join the room.
    /// @param startTime: UNIX time when the meeting will start.
    /// @param endTime: UNIX time when the meeting will end.
    /// @param cardCommitment: Initial card commitment from the Meeting Room chairman.
    /// @param chairman: Address of the Meeting Room creator.
    event MeetingRoomCreated(uint256 indexed roomId, uint256 bet, uint256 startTime, uint256 endTime, uint256 cardCommitment, address chairman);

    /// @dev Emitted when someone joins a Meeting Room
    /// @param roomId: ID of the Meeting Room that was joined.
    /// @param cardCommitment: Card commitment from the Meeting Room participant.
    /// @param participant: Address of the Meeting Room participant.
    event MeetingRoomJoined(uint256 indexed roomId, uint256 cardCommitment, address participant);
    
    /// @dev Emitted when a card gets revealed.
    /// @param roomId: ID of the Meeting Room.
    /// @param cardCommitment: Card commitment that is being revealed.
    /// @param cardId: ID of the Business Card that is being revealed.
    event CardRevealed(uint256 indexed roomId, uint256 cardCommitment, uint256 cardId);
    
    /// @dev Emitted when the winner of a meeting is drawn.
    /// @param roomId: ID of the Meeting Room.
    /// @param winner: Address that won the meeting.
    event WinnerDrawn(uint256 indexed roomId, address winner);

    /// @dev Creates a new Meeting Room.
    /// @param cardCommitment: Initial card commitment from the Meeting Room chairman.
    /// @param timeToMeetingStart: Time, in minutes, until the meeting starts.
    /// @param meetingDuration: Duration, in minutes, of the meeting. 
    function createMeetingRoom(uint256 cardCommitment, uint256 timeToMeetingStart, uint256 meetingDuration) external payable;

    /// @dev Allows the `msg.sender` to join a Meeting Room.
    /// @param roomId: ID of the Meeting Room to join.
    /// @param cardCommitment: Card commitment to join the room with.
    function joinMeetingRoom(uint256 roomId, uint256 cardCommitment) external payable;

    /// @dev Allows the `msg.sender` to reveal their committed Business Card, giving them a chance to win the staked funds.
    /// @param roomId: ID of the Meeting Room.
    /// @param cardCommitment: Card commitment that is being revealed.
    /// @param cardId: ID of the Business Card that was committed.
    /// @param salt: Random integer that was used to generate the card commitment.
    function revealCard(uint256 roomId, uint256 cardCommitment, uint256 cardId, uint256 salt) external;

    /// @dev Initiates the end of a meeting. If no eligible winner is found, the staked funds get locked inside the smart contract.
    /// @param roomId: ID of the Meeting Room.
    function finishMeeting(uint256 roomId) external;

    /// @dev Withdraw balance from this contract to fund the dev's tungsten cube collection.
    function withdraw() external;

    /// @dev Gets the information about a Meeting Room.
    /// @param roomId: ID of the Meeting Room.
    /// @return meetingRoom: Information about the Meeting Room.
    function getMeetingRoom(uint256 roomId) external view returns (Meeting memory);
}
