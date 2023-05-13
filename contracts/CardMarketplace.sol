//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBusinessCard.sol";
import "./interfaces/ICardMarketplace.sol";

contract CardMarketplace is ICardMarketplace, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Number of Business Cards that have been listed in the marketplace
    uint256 public totalListings;
    // Numer of Business Card listings that have been filled
    uint256 public filledListings;
    // Number of Business Card listings that have been cancelled
    uint256 public cancelledListings;
    
    // Business Card smart contract
    IBusinessCard immutable businessCardContract;
    // Minimum listing price, equal to the update price in bCard
    uint256 public minimumPrice = 0.05 ether;

    bool public saleStarted;

    mapping(uint256 => CardListing) private _idToCardListing;

    /// @dev Initializes the Card Marketplace smart contract.
    constructor(address businessCardAddress) {
        businessCardContract = IBusinessCard(businessCardAddress);
    }

    /// @dev See {ICardMarketplace-createCardListing}
    function createCardListing(uint256 cardId, uint256 price) external override nonReentrant returns (uint256) {
        if (!saleStarted) { revert MarketplaceIsPaused(); }
        if (price < minimumPrice) { revert PriceTooLow(); }

        totalListings++;

        _idToCardListing[totalListings] = CardListing(
            cardId,
            _msgSender(),
            address(0),  // No buyer for the item
            price,
            false,
            false
        );

        businessCardContract.transferFrom(_msgSender(), address(this), cardId);

        emit CardListingCreated(totalListings, cardId, _msgSender(), price);

        return totalListings;
    }
    
    /// @dev See {ICardMarketplace-cancelCardListing}
    function cancelCardListing(uint256 itemId) external override {
        uint256 cardId = _idToCardListing[itemId].cardId;

        if (cardId == 0) { revert MarketItemDoesNotExist(); }
        if (_idToCardListing[itemId].seller != _msgSender()) { revert MsgCallerIsNotTheSeller(); }

        _idToCardListing[itemId].buyer = _msgSender();
        _idToCardListing[itemId].isCancelled = true;
        cancelledListings++;

        businessCardContract.transferFrom(address(this), _msgSender(), cardId);

        emit CardListingCancelled(itemId, cardId);
    }
    
    /// @dev See {ICardMarketplace-buyListedCard}
    function buyListedCard(uint256 itemId, string calldata newCardName, CardProperties calldata newCardProperties) external payable override nonReentrant {
        if (!saleStarted) { revert MarketplaceIsPaused(); }
        
        uint256 price = _idToCardListing[itemId].price;
        uint256 cardId = _idToCardListing[itemId].cardId;

        // Buyer must pay the seller plus the oracle fee
        if (msg.value < price + ORACLE_FEE) { revert PriceTooLow(); }

        _idToCardListing[itemId].isSold = true;
        _idToCardListing[itemId].buyer = _msgSender();
        filledListings++;

        // Business Card update
        businessCardContract.updateCardData{ value: ORACLE_FEE }(cardId, newCardName, newCardProperties);

        address seller = _idToCardListing[itemId].seller;

        (bool success, ) = payable(seller).call{value: price}("");
        if (!success) { revert ValueTransferFailed(); }

        businessCardContract.transferFrom(address(this), _msgSender(), cardId);

        emit CardListingFilled(itemId, cardId, seller, _msgSender(), price);
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
        saleStarted = true;
    }
    
    /// @dev See {ICardMarketplace-pauseMarketplace}
    function pauseMarketplace() external override onlyOwner {
        saleStarted = false;
    }
    
    /// @dev See {ICardMarketplace-withdraw}
    function withdraw() external override onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");

        if (!success) { revert(); }
    }
}
