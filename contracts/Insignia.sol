/*
 @title Inkso Insignia
 @author: @bozp
 @dev: @bozp
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {
    LSP8IdentifiableDigitalAssetInitAbstract
} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAssetInitAbstract.sol";
import {LSP2Utils} from "@lukso/lsp-smart-contracts/contracts/LSP2ERC725YJSONSchema/LSP2Utils.sol";
import {_INTERFACEID_LSP7} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/LSP7Constants.sol";
import {_LSP4_CREATORS_ARRAY_KEY, _LSP4_CREATORS_MAP_KEY_PREFIX, _LSP4_METADATA_KEY} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";
import {IInsigniaFactory} from "./interfaces/IInsigniaFactory.sol";

contract Insignia is LSP8IdentifiableDigitalAssetInitAbstract, ReentrancyGuard {
    uint256 public freeSupply;
    uint256 public paidSupply;
    uint256 public burnSupply;
    bytes collectionLSP4MetadataUri;
    bytes lsp4MetadataUri;
    bytes lsp4BidMetadataUri;
    address factoryContract;

    error InsufficientBalance();
    error NotActive();
    error TokenDoesntExist();
    error incorrectPermissions();
    error PaymentSendFailed();
    error SoulBoundToken();
    error NotBiddingContract();

    // Event to emit when a new LSP8 token is created
    event InsigniaMinted(address indexed ownerAddress, bytes32 indexed tokenId);
    event InsigniaPaidMinted(address indexed ownerAddress, bytes32 indexed tokenId);
    event InsigniaBurned(address indexed burnerAddress, bytes32 indexed tokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        address challengeOwner_,
        bytes memory collectionLSP4MetadataUri_,
        bytes memory lsp4MetadataUri_,
        bytes memory lsp4BidMetadataUri_,
        address factoryContract_
    )
        external virtual initializer
    {
        collectionLSP4MetadataUri = collectionLSP4MetadataUri_;
        lsp4MetadataUri = lsp4MetadataUri_;
        lsp4BidMetadataUri = lsp4BidMetadataUri_;
        factoryContract = factoryContract_;

        _initialize(
            name_,
            "inkso-tx-dev",
            challengeOwner_,
            1,
            0
        );

        _setData(_LSP4_CREATORS_ARRAY_KEY, abi.encodePacked(uint128(1)));
        _setData(LSP2Utils.generateArrayElementKeyAtIndex(_LSP4_CREATORS_ARRAY_KEY,0), abi.encodePacked(challengeOwner_));
        _setData(LSP2Utils.generateMappingKey(_LSP4_CREATORS_MAP_KEY_PREFIX,bytes20(challengeOwner_)), abi.encodePacked(_INTERFACEID_LSP7, uint128(0)));
        
		_setData(_LSP4_METADATA_KEY, collectionLSP4MetadataUri);
    }
    
    function _initialize(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        uint256 lsp4TokenType_,
        uint256 lsp8TokenIdFormat_
    ) internal virtual override onlyInitializing {
        LSP8IdentifiableDigitalAssetInitAbstract._initialize(
            name_,
            symbol_,
            newOwner_,
            lsp4TokenType_,
            lsp8TokenIdFormat_
        );
    }

    function mint(address to) public payable nonReentrant onlyOwner {
        uint256 tokenSupply = paidSupply + freeSupply;
        uint256 pricePerToken = IInsigniaFactory(factoryContract).getSendPrice();

        if (msg.value != pricePerToken) revert InsufficientBalance();

        (bool success,  ) = payable(factoryContract).call{value: msg.value}("");
        if ( ! success ) revert PaymentSendFailed();

        uint256 tokenId = ++tokenSupply;
		_setDataForTokenId( bytes32(tokenId), _LSP4_METADATA_KEY, lsp4MetadataUri);
        ++freeSupply;
        _mint(to, bytes32(tokenId), true, "");

        emit InsigniaMinted(to, bytes32(tokenId));
    }

    function bidMint(address to) external payable nonReentrant {
        uint256 tokenSupply = paidSupply + freeSupply;
        if ( msg.sender != IInsigniaFactory(factoryContract).getBidContract() ) revert NotBiddingContract();
        
        uint256 tokenId = ++tokenSupply;
		_setDataForTokenId( bytes32(tokenId), _LSP4_METADATA_KEY, lsp4BidMetadataUri);
        ++paidSupply;
        _mint(to, bytes32(tokenId), true, "");

        emit InsigniaPaidMinted(to, bytes32(tokenId));
    }

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        if (amount > address(this).balance) revert InsufficientBalance();

        (bool success, ) = msg.sender.call{value: amount}("");
        if ( ! success ) revert PaymentSendFailed();
    }

    function burn(bytes32 tokenId) external nonReentrant {
        if (!_exists(tokenId)) revert TokenDoesntExist();
        address _owner = tokenOwnerOf(tokenId);
        if (msg.sender != _owner && msg.sender != owner()) revert incorrectPermissions();
        ++burnSupply;
        _burn(tokenId, "");
        emit InsigniaBurned(msg.sender, tokenId);
    }

    function transfer(
        address from,
        address to,
        bytes32 tokenId,
        bool force,
        bytes memory data
    ) public virtual override {
        if ( true ) revert SoulBoundToken();
    }

    function getFreeCount() public view returns (uint256) {
        return freeSupply;
    }
    
    function getPaidCount() public view returns (uint256) {
        return paidSupply;
    }
    
    function getBurnCount() public view returns (uint256) {
        return burnSupply;
    }
}