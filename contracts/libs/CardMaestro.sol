//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import { PRECISION } from "../libs/Constants.sol";

/// @dev Functions for computing winning chances between cards.
library CardMaestro {
    /// @dev Computes the winning chance that player A has against player B.
    /// @param genesA: Player A's Business Card genes.
    /// @param genesB: Player B's Business Card genes.
    /// @return winningChance: Chance that Player A's Business Card would win against player B's Business Card to 6 significant figures. 
    function getWinningChanceAgainst(uint256 genesA, uint256 genesB) internal pure returns (uint256) {
        /* 
         *  genes: integer, characteristics that make up the NFT, a 30 digit number,
         *  00.00.00.00.00.00.00.00.00.00.00.00.00.0000:
         *      [0:2]: background
         *      [2:4]: type of paper
         *      [4:6]: paper color
         *      [6:8]: font used
         *      [8:10]: address 
         *      [10:12]: cranberry juice
         *      [12:14]: shadow type
         *      [14:16]: watermark
         *      [16:18]: footprint
         *      [18:20]: defaced
         *      [20:22]: lettering
         *      [22:24]: gold edges
         *      [24:26]: washed
         *      [26:30]: phone number
        */


        // TODO: how to compute these in a bretty good gamified model?
        return uint256(keccak256(abi.encodePacked(genesA, genesB))) % PRECISION;  // temporary solution
    }
}
