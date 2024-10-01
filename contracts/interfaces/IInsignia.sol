/*
 @title Inkso Insignia
 @author: @bozp
 @dev: @bozp
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IInsignia {
    function bidMint(address to) external;
    function owner() external view returns (address);
}