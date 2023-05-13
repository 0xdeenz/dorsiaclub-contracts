//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @dev Defines the values for the Business Card that get stored on-chain.
struct Card {
    /// Unique name that is assigned to this Business Card
    string name;
    /// Random integer that encodes the characteristics of the Business Card and is generated at mint time.
    uint256 genes;
}

/// @dev Defines the values for the Business Card that are not stored on-chain, and are instead sent to the oracle. 
struct CardProperties {
    string position;
    string twitterAccount;
    string telegramAccount;
    string telegramGroup;
    uint256 discordAccount;
    string discordGroup;
    string githubUsername;
    string website;
}

/// @dev Defines a Business Card listing in the marketplace. 
struct CardListing {
    uint256 itemId;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool isSold;
    bool isCancelled;
}