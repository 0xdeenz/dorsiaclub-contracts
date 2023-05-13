// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDorsiaClubToken.sol";

contract DorsiaClubToken is IDorsiaClubToken, ERC20Burnable, Ownable {
    /// @dev Initializes the Dorsia Club Token smart contract.
    constructor() ERC20("Dorsia Club Token", "DCT") {
        _mint(msg.sender, DCT_AIRDROP_SUPPLY * 10 ** decimals());
        _mint(tx.origin, (MAX_DCT_SUPPLY - DCT_AIRDROP_SUPPLY) * 10 ** decimals());
    }
}
