//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBusinessCard.sol";
import "./interfaces/ICardMarketplace.sol";

contract CardMarketplace is ICardMarketplace, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Number of Business Cards that have been listed in the marketplace.
    uint256 public totalListings;
    // Numer of Business Card listings that have been filled.
    uint256 public filledListings;
    // Number of Business Card listings that have been cancelled.
    uint256 public cancelledListings;
    
    // Business Card smart contract.
    IBusinessCard immutable businessCard;

    // Whether the trading of Business Cards is currently active, which starts as true.
    bool public marketplaceActive = true;

    /// @dev Gets a listing ID and returns the corresponding CardListing struct.
    mapping(uint256 => CardListing) private _idToCardListing;

    /// @dev Throws if the listing has been cancelled or filled.
    /// @param itemId: ID of the listing.
    modifier activeListing(uint256 itemId) {
        if (_idToCardListing[itemId].isSold) { revert ListingWasFilled(); }
        if (_idToCardListing[itemId].isCancelled) { revert ListingWasCancelled(); }
        _;
    }

    /// @dev Initializes the Card Marketplace smart contract.
    /// @param businessCardAddress: Address for the Business Card smart contract.
    constructor(address businessCardAddress) {
        businessCard = IBusinessCard(businessCardAddress);
    }

    /// @dev See {ICardMarketplace-createCardListing}
    function createCardListing(uint256 cardId, uint256 price) external override nonReentrant {
        if (!marketplaceActive) { revert MarketplaceIsPaused(); }
        if (price < MIN_LISTING_PRICE) { revert PriceTooLow(); }

        totalListings++;

        _idToCardListing[totalListings] = CardListing(
            cardId,
            _msgSender(),
            address(0),  // No buyer for the item
            price,
            false,
            false
        );

        businessCard.transferFrom(_msgSender(), address(this), cardId);

        emit CardListingCreated(totalListings, cardId, _msgSender(), price);
    }
    
    /// @dev See {ICardMarketplace-cancelCardListing}
    function cancelCardListing(uint256 itemId) external override activeListing(itemId) {
        uint256 cardId = _idToCardListing[itemId].cardId;

        if (cardId == 0) { revert ListingDoesNotExist(); }
        if (_idToCardListing[itemId].seller != _msgSender()) { revert CallerIsNotTheSeller(); }

        _idToCardListing[itemId].buyer = _msgSender();
        _idToCardListing[itemId].isCancelled = true;
        cancelledListings++;

        businessCard.transferFrom(address(this), _msgSender(), cardId);

        emit CardListingCancelled(itemId, cardId);
    }

    /// @dev See {ICardMarketplace-buyListedCard}
    function buyListedCard(uint256 itemId) external payable override nonReentrant activeListing(itemId) {
        uint256 cardId = _idToCardListing[itemId].cardId;
        uint256 price = _idToCardListing[itemId].price;
        
        _buyListedCard(itemId, cardId, price);
    }
    
    /// @dev See {ICardMarketplace-buyListedCard}
    function buyAndUpdateListedCard(
        uint256 itemId, 
        string calldata newCardName, 
        CardProperties calldata newCardProperties
    ) external payable override nonReentrant activeListing(itemId) {
        uint256 cardId = _idToCardListing[itemId].cardId;
        uint256 price = _idToCardListing[itemId].price;

        // Buyer must pay the seller plus the oracle fee plus the update price
        if (msg.value < price + ORACLE_FEE + UPDATE_PRICE) { revert PriceTooLow(); }

        // Business Card update
        businessCard.updateCardData{ value: ORACLE_FEE + UPDATE_PRICE }(cardId, newCardName, newCardProperties);

        _buyListedCard(itemId, cardId, price);
    }

    /// @dev See {ICardMarketplace-getMarketListings}
    function getMarketListings() external view override returns (CardListing[] memory cardListings) {
        uint256 availableItemsCount = totalListings - filledListings - cancelledListings;
        cardListings = new CardListing[](availableItemsCount);

        uint256 listingIndex;
        for(uint256 i = 0; i < totalListings; ++i) {
            CardListing memory listing = _idToCardListing[i + 1];

            if (listing.buyer != address(0)) continue;

            cardListings[listingIndex] = listing;
            listingIndex++;
        }

        return cardListings;
    }
    
    /// @dev See {ICardMarketplace-getMarketListingsByAddress}
    function getMarketListingsByAddress(address account, bool isSeller) external view override returns (CardListing[] memory cardListings) {
        uint256 listingCount;
        uint256 listingIndex;

        for (uint256 i = 0; i < totalListings; i++) {
            if ((isSeller ?  _idToCardListing[i + 1].seller :  _idToCardListing[i + 1].buyer) != account) continue;
            listingCount++;
        }

        cardListings = new CardListing[](listingCount);

        for (uint256 i = 0; i < totalListings; i++) {
            if ((isSeller ?  _idToCardListing[i + 1].seller :  _idToCardListing[i + 1].buyer) != account) continue;

            cardListings[listingIndex] =_idToCardListing[i + 1];

            listingIndex++;
        }
    }
    
    /// @dev See {ICardMarketplace-getLatestListingByCard}
    function getLatestListingByCard(uint256 cardId) external view override returns (CardListing memory cardListing) {
        for (uint256 i = totalListings; i > 0; i--) {
            cardListing = _idToCardListing[i];
            if (cardListing.cardId != cardId) continue;
            return cardListing;
        }

        revert CardWasNotListed();
    }
    
    /// @dev See {ICardMarketplace-startMarketplace}
    function startMarketplace() external override onlyOwner {
        marketplaceActive = true;
    }
    
    /// @dev See {ICardMarketplace-pauseMarketplace}
    function pauseMarketplace() external override onlyOwner {
        marketplaceActive = false;
    }
    
    /// @dev See {ICardMarketplace-withdraw}
    function withdraw() external override onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{ value: balance }("");

        if (!success) { revert(); }
    }

    /// @dev Purchases a listed Business Card from the Marketplace.
    /// @param itemId: ID of the listing that is to be bought.
    /// @param cardId: ID of the Business Card that was listed.
    /// @param price: Price the Business Card was listed for.
    function _buyListedCard(uint256 itemId, uint256 cardId, uint256 price) internal {
        if (cardId == 0) { revert ListingDoesNotExist(); }
        if (_idToCardListing[itemId].isSold) { revert ListingWasFilled(); }
        if (_idToCardListing[itemId].isCancelled) { revert ListingWasCancelled(); }
        if (!marketplaceActive) { revert MarketplaceIsPaused(); }

        // Buyer must pay the seller
        if (msg.value < price) { revert PriceTooLow(); }

        _idToCardListing[itemId].isSold = true;
        _idToCardListing[itemId].buyer = _msgSender();
        filledListings++;

        address seller = _idToCardListing[itemId].seller;

        (bool success, ) = payable(seller).call{ value: price }("");
        if (!success) { revert ValueTransferFailed(); }

        businessCard.transferFrom(address(this), _msgSender(), cardId);

        emit CardListingFilled(itemId, cardId, seller, _msgSender(), price);
    }
}
