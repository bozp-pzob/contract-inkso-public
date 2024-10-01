/*
 @title Inkso Insignia Factory Interface
 @author: @bozp
 @dev: @bozp
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IInsigniaFactory {
    function getBidContract() external view returns (address);
    function getSendPrice() external view returns (uint256);
    function getDeployedTokens() external view returns (address[] memory);
}