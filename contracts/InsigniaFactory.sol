/*
 @title Inkso Insignia Factory
 @author: @bozp
 @dev: @bozp
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Bidder} from "./Bidder.sol";

interface InitializerLSP8 {
    function initialize(
        string memory name_,
        address challengeOwner_,
        bytes memory collectionLSP4MetadataUri_,
        bytes memory lsp4MetadataUri_,
        bytes memory lsp4BidMetadataUri_,
        address factoryContract_
    ) external;
}

contract InsigniaFactory is Ownable {
    address public latestInsigniaImplementation;
    address public latestBidderImplementation;

    // Keep track of deployed tokens
    address[] public deployedTokens;
    mapping (address => address[]) private deployedTokensByUser;
    uint256 public priceToCreate = 0.1 ether;
    uint256 public priceToSend = 0.1 ether;

    // Event to emit when a new LSP8 token is created
    event InsigniaCreated(address indexed tokenAddress, address indexed bidderAddress);

    error InsufficientBalance();

    function setLatestImplementation(address _latestInsigniaImplementation) external onlyOwner {
        latestInsigniaImplementation = _latestInsigniaImplementation;
    }

    function setLatestBidderImplementation(address _latestBidderImplementation) external onlyOwner {
        latestBidderImplementation = _latestBidderImplementation;
    }
    
    function setCreatePrice(uint256 amount) external onlyOwner {
        priceToCreate = amount;
    }
    
    function setSendPrice(uint256 amount) external onlyOwner {
        priceToSend = amount;
    }

    function createInsignia(
        string memory name_,
        address challengeOwner_,
        bytes memory collectionLSP4MetadataUri,
		bytes memory lsp4MetadataUri,
		bytes memory lsp4BidMetadataUri
    ) public payable returns (address contractCreated) {
        require(latestInsigniaImplementation != address(0), "Insignia implementation not set");
        require(msg.value == priceToCreate, "Price to create Insignia isn't correct.");

        contractCreated = Clones.clone(latestInsigniaImplementation);
        InitializerLSP8(contractCreated).initialize(
            name_,
            msg.sender,
            collectionLSP4MetadataUri,
            lsp4MetadataUri, 
            lsp4BidMetadataUri,
            address(this)
        );

        deployedTokens.push(address(contractCreated));
        deployedTokensByUser[msg.sender].push(address(contractCreated));
        emit InsigniaCreated(address(contractCreated), address(latestBidderImplementation));
    }

    // Function to get all deployed LSP8 tokens
    function getDeployedTokens() public view returns (address[] memory) {
        return deployedTokens;
    }

    // Function to get all deployed LSP8 tokens
    function getDeployedTokensByUser(address user) public view returns (address[] memory) {
        return deployedTokensByUser[user];
    }
    
    // Function to get bid contract address
    function getBidContract() public view returns (address) {
        return latestBidderImplementation;
    }

    // Function to get current send price
    function getSendPrice() public view returns (uint256) {
        return priceToSend;
    }
    
    // Function to get current create price
    function getCreatePrice() public view returns (uint256) {
        return priceToCreate;
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) revert InsufficientBalance();

        (bool success, ) = msg.sender.call{value: amount}(
            bytes.concat(bytes4(0), bytes(unicode"withdrawing"))
        );
        require(success, "Withdraw failed");
    }

    receive() external payable {}

    fallback() external payable {}
}