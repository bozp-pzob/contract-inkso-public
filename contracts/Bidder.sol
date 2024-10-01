/*
 @title Inkso Insignia
 @author: @bozp
 @dev: @bozp
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IInsignia} from "./interfaces/IInsignia.sol";
import {IInsigniaFactory} from "./interfaces/IInsigniaFactory.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bidder is ReentrancyGuard {
    struct Bid {
        address bidder;
        uint256 amount;
        bool accepted;
        address insigniaContract;
    }

    uint256 public bidCounter;
    mapping(uint256 => Bid) public bids;
    
    address factoryContract;

    event NewBid(uint256 bidId, address bidder, uint256 amount, address nftContract);
    event BidAccepted(uint256 bidId, address bidder, uint256 amount, address nftContract);
    event BidWithdrawn(uint256 bidId, address bidder, uint256 amount, address nftContract);

    modifier onlyNFTOwner(address insigniaContract) {
        require(msg.sender == IInsignia(insigniaContract).owner(), "Caller is not the owner of the target NFT contract.");
        _;
    }

    constructor(address factoryContract_) {
        bidCounter = 0;
        factoryContract = factoryContract_;
    }

    function placeBid(uint256 _insigniaContractIndex) public payable nonReentrant {
        address _insigniaContract = IInsigniaFactory(factoryContract).getDeployedTokens()[_insigniaContractIndex];
        
        require(msg.value >= 0, "Bid amount must be greater than or equal to 0.");
        require(_insigniaContract != address(0), "Invalid NFT contract address.");

        bids[bidCounter] = Bid({
            bidder: msg.sender,
            amount: msg.value,
            accepted: false,
            insigniaContract: _insigniaContract
        });

        emit NewBid(bidCounter, msg.sender, msg.value, _insigniaContract);
        bidCounter++;
    }

    function acceptBid(uint256 bidId) public payable nonReentrant onlyNFTOwner(bids[bidId].insigniaContract) {
        Bid storage bid = bids[bidId];
        require(bid.amount > 0, "Invalid bid.");
        require(!bid.accepted, "Bid already accepted.");

        bid.accepted = true;
        emit BidAccepted(bidId, bid.bidder, bid.amount, bid.insigniaContract);

        // // Mint the NFT from the external contract
        IInsignia(bid.insigniaContract).bidMint(bid.bidder);

        // // Transfer the bid amount to the owner
        uint256 amount95 = (bid.amount * 95) / 100;
        uint256 amount5 = bid.amount - amount95;

        (bool success, ) = factoryContract.call{value: amount5}(
            bytes.concat(bytes4(0), bytes(unicode"sending percentage"))
        );
        require(success, "ETH percentage failed");
        
        (bool owner_success, ) = IInsignia(bid.insigniaContract).owner().call{value: amount95}(
            bytes.concat(bytes4(0), bytes(unicode"sending bid to owner"))
        );
        require(owner_success, "ETH transfer failed");
    }

    function withdraw(uint256 bidId) public nonReentrant {
        Bid storage bid = bids[bidId];
        require(msg.sender == bid.bidder, "You are not the bidder.");
        require(!bid.accepted, "Cannot withdraw an accepted bid.");

        uint256 amount = bid.amount;
        bid.amount = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        emit BidWithdrawn(bidId, msg.sender, amount, bid.insigniaContract);
    }

    function getBidDetails(uint256 bidId) public view returns (address bidder, uint256 amount, bool accepted, address nftContract) {
        Bid memory bid = bids[bidId];
        return (bid.bidder, bid.amount, bid.accepted, bid.insigniaContract);
    }
}