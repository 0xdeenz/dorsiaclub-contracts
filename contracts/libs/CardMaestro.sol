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
        // TODO: how to compute these in a bretty good gamified model?
        return uint256(keccak256(abi.encodePacked(genesA, genesB))) % PRECISION;  // temporary solution
    }
}
