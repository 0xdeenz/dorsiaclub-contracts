// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./DorsiaToken.sol";
import "./interfaces/IBusinessCard.sol";
import "./libs/Utils.sol";

contract BusinessCard is IBusinessCard, ERC721Enumerable, Ownable {
    using StringUtils for bytes;

    /// @dev Gets a Business Card ID and returns the corresponding URI.
    mapping (uint256 => string) private _cardURIs;

    /// @dev Gets a Business Card ID and returns the corresponding genes.
    mapping (uint256 => Card) private _cardStats;
    
    /// @dev Gets a name and returns whether it was already reserved. Reserved names are stored in lowercase.
    mapping (string => bool) private _nameReserved;

    // Base URI.
    string public baseURI;

    // Default URI.
    string public defaultURI;

    // Address of the oracle.
    address public oracleAddress;
    
    /// @dev Gets a request ID and returns wheter it was processed by the oracle.
    mapping(uint256 => bool) public requests;

    // Business Card Marketplace address.
    address private marketplaceAddress;
    // Dorsia Club Token contract.
    DorsiaClubToken public DCT;

    bool public saleStarted;

    /// @dev Throws if the sale has not started.
    modifier activeSale() {
        if (!saleStarted) { revert SaleNotActive(); }
        _;
    }

    /// @dev Throws if the Business Card does not exist.
    /// @param cardId: ID of the Business Card.
    modifier existingCards(uint256 cardId) {
        if (!_exists(cardId)) { revert CardDoesNotExist(); }
        _;
    }

    /// @dev Initializes the Business Card smart contract.
    /// @param baseURI_: Base URI for all Business Cards.
    /// @param defaultURI_: Default URI for unminted/unprocessed Business Cards.
    /// @param oracleAddress_: Initial address for the oracle.
    constructor(string memory baseURI_, string memory defaultURI_, address oracleAddress_) ERC721("Business Card", "CARD") {
        baseURI = baseURI_;
        defaultURI = defaultURI_;
        oracleAddress = oracleAddress_;

        DCT = new DorsiaClubToken();
    }

    /// @dev See {IBusinessCard-getCard}
    function getCard(string calldata cardName, CardProperties calldata cardProperties) external payable override activeSale {
        if (totalSupply() >= MAX_SUPPLY) { revert SaleHasEnded(); }
        if (msg.value < MINT_PRICE) { revert PriceTooLow(); }

        if (!bytes(cardName).validateName()) { revert NameNotValid(); }
        if (_isNameReserved(cardName)) { revert NameIsTaken(); }
        if (!bytes(cardProperties.position).validatePosition()) { revert PositionNotValid(); }

        uint256 cardId = totalSupply() + 1;

        // Generating the random genes, defined by a 30 digit number
        // The server oracle will convert the genes to a string and add leading zeros, as tokenURIs are generated with this constraint
        // TODO: ~~improve make it harder to exploit
        uint256 genes = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, cardName, cardId))) % 10**30;

        // Generating a new Business Card
        _nameReserved[bytes(cardName).toLower()] = true;
        _cardStats[cardId] = Card(cardName, genes);
        _safeMint(_msgSender(), cardId);
        _updateTokenURI(cardId, genes, cardName, cardProperties);

        DCT.transfer(_msgSender(), DCT_AIRDROP);
    }

    /// @dev See {IBusinessCard-updateCardData}
    function updateCardData(uint256 cardId, string calldata newCardName, CardProperties calldata newCardProperties) external payable override activeSale {
        if (!_isApprovedOrOwner(_msgSender(), cardId)) { revert CallerMustBeOwnerOrApproved(); }
        if (msg.value < UPDATE_PRICE && _msgSender() != marketplaceAddress) { revert PriceTooLow(); }

        if (bytes(newCardName).length != 0 && !bytes(newCardName).validateName()) { revert NameNotValid(); }
        if (_isNameReserved(newCardName)) { revert NameIsTaken(); }
        if (bytes(newCardProperties.position).length != 0 && !bytes(newCardProperties.position).validatePosition()) { revert PositionNotValid(); }

        // Only change the name if specified
        if (bytes(newCardName).length > 0) {
            _nameReserved[bytes(_cardStats[cardId].name).toLower()] = false;
            _nameReserved[bytes(newCardName).toLower()] = true;
            
            _cardStats[cardId].name = newCardName;
        }

        _updateTokenURI(cardId, _cardStats[cardId].genes, newCardName, newCardProperties);
    }

    /// @dev See {IBusinessCard-swapCardData}
    function swapCardData(uint256 cardId1, uint256 cardId2) external payable override activeSale {
        if (!_isApprovedOrOwner(_msgSender(), cardId1) || !_isApprovedOrOwner(_msgSender(), cardId2)) { revert CallerMustBeOwnerOrApproved(); }
        if (msg.value < UPDATE_PRICE) { revert PriceTooLow(); }

        if (requests[cardId1] || requests[cardId2]) { revert RequestBeingProcessed(); }

        // Swapping names between tokens
        string memory name1 = _cardStats[cardId1].name;
        _cardStats[cardId1].name = _cardStats[cardId2].name;
        _cardStats[cardId2].name = name1;

        // Requests now pending
        requests[cardId1] = true;
        requests[cardId2] = true;

        // Emitting a single swap request to the oracle -- processed differently
        emit CardDataSwapRequest(cardId1, cardId2, _cardStats[cardId1].genes, _cardStats[cardId2].genes);

        // Fund the server oracle with enough funds for the callback transaction
        (bool success, ) = payable(oracleAddress).call{value: ORACLE_FEE}("");
        if (!success) { revert ValueTransferFailed(); }
    }   

    /// @dev See {IBusinessCard-startSale}
    function startSale() external override onlyOwner {
        if (oracleAddress == address(0)) { revert OracleIsNotDefined(); }
        saleStarted = true;
    }

    /// @dev See {IBusinessCard-pauseSale}
    function pauseSale() external override onlyOwner {
        saleStarted = false;
    }

    /// @dev See {IBusinessCard-updateCallback}
    function updateCallback(uint256 cardId, string memory cardURI) external override {
        _callback(cardId, cardURI);
    }

    /// @dev See {IBusinessCard-swapCallback}
     function swapCallback(uint256 cardId1, uint256 cardId2, string memory cardURI1, string memory cardURI2) external override {
        _callback(cardId1, cardURI1);
        _callback(cardId2, cardURI2);
    }

    /// @dev See {IBusinessCard-setOracle}
    function setOracle(address oracleAddress) external override onlyOwner {
        oracleAddress = oracleAddress;
    }

    /// @dev See {IBusinessCard-setMarketplace}
    function setMarketplace(address marketplaceAddress) external override onlyOwner {
        marketplaceAddress = marketplaceAddress;
    }
    
    /// @dev See {IBusinessCard-setBaseURI}
    function setBaseURI(string memory baseURI_) external override onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev See {IBusinessCard-devWorksHard}
    function devWorksHard() external override onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{ value: balance }("");

        if (!success) { revert(); }
    }

    /// @dev See {IBusinessCard-isNameReserved}
    function isNameReserved(string calldata name) external override view returns (bool) {
        return _isNameReserved(name);
    }

    /// @dev See {IBusinessCard-getCardStats}
    function getCardStats(uint256 cardId) external override view existingCards(cardId) returns (Card memory) {
        return _cardStats[cardId];
    }

    /// @dev See {IBusinessCard-getCardGenes}
    function getCardGenes(uint256 cardId) external override view existingCards(cardId) returns (uint256) {
        return _cardStats[cardId].genes;
    }

    /// @dev See {IERC721Metadata-tokenURI}
    function tokenURI(uint256 cardId) public view override existingCards(cardId) returns (string memory) {
        string memory cardURI = _cardURIs[cardId];

        if (bytes(cardURI).length == 0) {
            return string(abi.encodePacked(baseURI, defaultURI));
        } else {
            return string(abi.encodePacked(baseURI, cardURI));
        }
    }

    /// @dev See {IBusinessCard-isNameReserved}
    function _isNameReserved(string calldata name) internal view returns (bool) {
        return _nameReserved[bytes(name).toLower()];
    }

    /// @dev Emits an event for the oracle to update a certain token URI with the newly defined Card struct.
    /// @param cardId: ID of the Business Card.
    /// @param genes: Random integer encoding the characteristics of this Business Card.
    /// @param cardName: Unique name assigned to this Business Card.
    /// @param cardProperties: Values for this Business Card that are not stored on-chain.
    function _updateTokenURI(uint256 cardId, uint256 genes, string calldata cardName, CardProperties calldata cardProperties) internal {
        if (
            bytes(cardProperties.twitterAccount).length > 15 ||
            bytes(cardProperties.telegramAccount).length > 32 ||
            bytes(cardProperties.githubUsername).length > 39 ||
            bytes(cardProperties.website).length > 50
        ) { revert PropertiesNotValid(); }
    
        // TODO: this necessary? require(_exists(_cardId));

        // Calls for updating the token can only be made if it is not being processed already
        if (requests[cardId]) { revert RequestBeingProcessed(); }
        requests[cardId] = true;

        // Fund the server oracle with enough funds for the callback transaction
        (bool success, ) = payable(oracleAddress).call{value: ORACLE_FEE}("");
        if (!success) { revert ValueTransferFailed(); }
        
        emit CardDataUpdateRequest(cardId, genes, cardName, cardProperties);
    }

    /// @dev Updates a certain token URI and clears the corresponding update request.
    function _callback(uint256 cardId, string memory cardURI) internal {
        if (_msgSender() != oracleAddress) { revert CallerMustBeOracle(); }
        if (!requests[cardId]) { revert RequestNotInPendingList(); }

        _cardURIs[cardId] = cardURI;
        delete requests[cardId];

        emit CardURIUpdated(cardId, cardURI);
    }
}
