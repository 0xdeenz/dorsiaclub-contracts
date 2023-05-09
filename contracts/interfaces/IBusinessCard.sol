// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

/// @title Business Card interface.
/// @dev Interface of the NFT Business Card smart contract.
interface IBusinessCard is IERC721Enumerable {
    error SaleNotActive();
    error SaleHasEnded();
    error PriceTooLow();

    error NameNotValid();
    error NameIsTaken();
    error PositionNotValid();
    error PropertiesNotValid();

    error CallerMustBeOwnerOrApproved();

    error RequestBeingProcessed();
    
    error OracleIsNotDefined();
    error UpdatePriceMustCoverOracleFee();
    error CallerMustBeOracle();
    error RequestNotInPendingList();

    error ValueTransferFailed();

    error CardDoesNotExist();
    
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

    /// @dev Emitted when a new request is made to the oracle to change a Business Card's URI.
    /// @param cardId: ID of the Business Card.
    /// @param genes: Random integer encoding the characteristics of this Business Card.
    /// @param name: Unique name assigned to this Business Card.
    /// @param cardProperties: Values for this Business Card that are not stored on-chain.
    event CardDataUpdateRequest(uint256 cardId, uint256 genes, string name, CardProperties cardProperties);

    /// @dev Emitted when a new request is made to the oracle to change two Business Card's URI by swapping their name, position and properties.
    /// @param cardId1: ID of the first Business Card.
    /// @param cardId2: ID of the second Business Card.
    /// @param genes1: Random integer encoding the characteristics of the first Business Card.
    /// @param cardId1: Random integer encoding the characteristics of the second Business Card.
    event CardDataSwapRequest(uint256 cardId1, uint256 cardId2, uint256 genes1, uint256 genes2);

    /// @dev Emitted when the oracle updates a Business Card's URI.
    /// @param cardId: ID of the Business Card that was updated.
    /// @param newCardURI: New URI for this Business Card.
    event CardURIUpdated(uint256 cardId, string newCardURI);

    /// @dev Mints a new NFT Business Card to the msg.sender.
    /// @param cardName: Unique name assigned to this Business Card.
    /// @param cardProperties: External values for the Business Card.
    function getCard(string calldata cardName, CardProperties calldata cardProperties) external payable;

    /// @dev Changes the name and/or properties of a Business Card owned by the msg.sender.
    /// @param cardId: ID of the Business Card to be updated.
    /// @param newCardName: New unique name assigned to this Business Card.
    /// @param newCardProperties: New external values for the Business Card.
    function updateCardData(uint256 cardId, string calldata newCardName, CardProperties calldata newCardProperties) external payable;

    /// @dev Swaps the name, position and properties between two Business Cards owned by the msg.sender, so as to prevent "name snipers".
    /// @param cardId1: ID of the first Business Card.
    /// @param cardId2: ID of the second Business Card.
    function swapCardData(uint256 cardId1, uint256 cardId2) external payable;

    /// @dev Starts the sale, allowing for the minting of Business Cards.
    function startSale() external;

    /// @dev Pauses the sale.
    function pauseSale() external;

    /// @dev Callback function for the oracle to update a Business Card URI.
    /// @param cardId: ID of the Business Card to be updated.
    /// @param cardURI: New URI for this Business Card.
    function updateCallback(uint256 cardId, string memory cardURI) external;

    /// @dev Callback function for the oracle to update two Business Card URIs by swapping their properties.
    /// @param cardId1: ID of the first Business Card.
    /// @param cardId2: ID of the second Business Card.
    /// @param cardURI1: New URI for the first Business Card.
    /// @param cardURI2: New URI for the second Business Card.
    function swapCallback(uint256 cardId1, uint256 cardId2, string memory cardURI1, string memory cardURI2) external;

    /// @dev Sets up a new oracle that handles the dynamic aspect of the Business Card.
    /// @param oracleAddress: New address of the oracle.
    function setOracle(address oracleAddress) external;

    /// @dev Sets up a Marketplace allowing the native trading of Business Cards.
    /// @param marketplaceAddress: New address of the marketplace.
    function setMarketplace(address marketplaceAddress) external;

    /// @dev Changes the Business Card update price.
    /// @param newUpdatePrice: New price for updating Business Cards.
    function modifyUpdatePrice(uint256 newUpdatePrice) external;

    /// @dev Withdraw balance from this contract to fund the dev's tungsten cube collection.
    function devWorksHard() external;

    /// @dev Returns wheter the given name is reserved.
    /// @param name: Name to be checked.
    /// @return bool: Whether the name is reserved.
    function isNameReserved(string calldata name) external view returns (bool);

    /// @dev Returns the stats of the given Business Card.
    /// @param cardId: ID of the Business Card.
    /// @return Card: Name and genes of the Business Card.
    function getCardStats(uint256 cardId) external view returns (Card memory);
}
