//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { CardProperties, CardListing } from "../libs/Structs.sol";
import { ORACLE_FEE, UPDATE_PRICE } from "../libs/Constants.sol";

interface ICardMarketplace {
    error MarketplaceIsPaused();
    error PriceTooLow();

    error MarketItemDoesNotExist();
    error MsgCallerIsNotTheSeller();

    error ValueTransferFailed();

    error CardWasNotListed();

    /// @dev Emitted when a new Business Card is listed in the marketplace.
    /// @param itemId: ID of the listing that is being created.
    /// @param cardId: ID of the Business Card that is being listed.
    /// @param seller: Address that is listing the Business Card.
    /// @param price: Price the Business Card is being listed for.
    event CardListingCreated(uint256 indexed itemId, uint256 indexed cardId, address seller, uint256 price);

    /// @dev Emitted when a Business Card listing gets cancelled.
    /// @param itemId: ID of the listing that was cancelled.
    /// @param cardId: ID of the Business Card.
    event CardListingCancelled(uint256 indexed itemId, uint256 indexed cardId);

    /// @dev Emitted when a Business Card listing gets filled.
    /// @param itemId: ID of the listing.
    /// @param cardId: ID of the Business Card that was transacted.
    /// @param seller: Address that listed the Business Card.
    /// @param buyer: Address that bought the Business Card listing.
    /// @param price: Price the Business Card was purchased for.
    event CardListingFilled(uint256 indexed itemId, uint256 indexed cardId, address seller, address buyer, uint256 price);

    /// @dev Lists a Business Card on the Marketplace.
    /// @param cardId: ID of the Business Card that is being listed.
    /// @param price: Price the Business Card is being listed for.
    /// @return itemId: ID of the listing that was created.
    function createCardListing(uint256 cardId, uint256 price) external returns (uint256);

    /// @dev Cancels a Business Card listing.
    /// @param itemId: ID of the listing that is to be cancelled.
    function cancelCardListing(uint256 itemId) external;

    /// @dev Purchases a listed Business Card from the Marketplace.
    /// @param itemId: ID of the listing that is to be bought.
    /// @param newCardName: New name that will be assigned to the Business Card after purchase.
    /// @param newCardProperties: New properties that will be assigned to the Business Card after purchase.
    function buyListedCard(uint256 itemId, string calldata newCardName, CardProperties calldata newCardProperties) external payable;

    /// @dev Gets the Business Card listings that are currently active in the Marketplace.
    /// @return cardListings: listings that are currently active.
    function getMarketListings() external view returns(CardListing[] memory);
    
    /// @dev Gets the Business Card listings related to an address either as a buyer or a seller.
    /// @param account: Address of interest.
    /// @param isSeller: Boolean value indicating whether to find the listings for this address as a seller or as a buyer.
    /// @return cardListings: Business Card listings related to this address.
    function getMarketListingsByAddress(address account, bool isSeller) external view returns (CardListing[] memory);

    /// @dev Gets the latest listing in the marketplace for a Business Card. Reverts if the card was never listed.
    /// @param cardId: ID of the Business Card.
    /// @return cardListing: Last Marketplace listing for this Business Card.
    function getLatestListingByCard(uint256 cardId) external view returns (CardListing memory);

    /// @dev Starts the Business Card Marketplace.
    function startMarketplace() external;

    /// @dev Pauses the Business Card Marketplace.
    function pauseMarketplace() external;

    /// @dev Withdraw balance from this contract to fund the dev's tungsten cube collection.
    function withdraw() external;
}
