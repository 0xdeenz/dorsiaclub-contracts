//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// Maximum number of Business Cards there will ever be
uint256 constant MAX_SUPPLY = 2000;
// Token mint price
uint256 constant MINT_PRICE = 0.01 ether;
// Token URI update / swap price
uint256 constant UPDATE_PRICE = 0.002 ether;
// Oracle update transaction gas price
uint256 constant ORACLE_FEE = 0.0005 ether;

// Maximum supply of $DCT tokens
uint256 constant MAX_DCT_SUPPLY = 212_555_6342;
// Airdropped $DCT for purchasing a Business Card
uint256 constant DCT_AIRDROP = 212_555;
// Total $DCT allocation for airdrops
uint256 constant DCT_AIRDROP_SUPPLY = DCT_AIRDROP * MAX_SUPPLY;

// Maximum meeting participants; limitation arises from having to loop through an array when revealing cards
uint256 constant MAXIMUM_MEETING_PARTICIPANTS = 10;
// Minimum time, in minutes, that must be waited until a meeting starts
uint256 constant MINIMUM_TIME_TO_MEETING_START = 1; 
// Maximum time, in minutes, that must be waited until a meeting starts
uint256 constant MAXIMUM_TIME_TO_MEETING_START = 10;
// Minimum duration, in minutes, that a meeting can take
uint256 constant MINIMUM_MEETING_DURATION = 1;
// Maximum duration, in minutes, that a meeting can take
uint256 constant MAXIMUM_MEETING_DURATION = 10;
// Significant figures used to compute chances
uint256 constant PRECISION = 1e6;
