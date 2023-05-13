// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IBusinessCard.sol";

/// @dev Useful functions for validating the name and position of Business Cards.
library StringUtils {
    error NonValidCharacters();

    uint256 constant MAX_NAME_CHARACTERS = 22;
    uint256 constant MAX_POSITION_CHARACTERS = 32;

    /// @dev Checks that the name string is valid: alphanumeric with some special characters and spaces without leading or trailing space and under `MAX_NAME_CHARACTERS` characters.
    /// @param stringBytes: Bytes array for the name string. 
    function validateName(bytes calldata stringBytes) internal pure returns (bool) {
        if (!validateStringBytes(stringBytes)) { revert NonValidCharacters(); }
        
        if(
            stringBytes.length == 0 || stringBytes.length > MAX_NAME_CHARACTERS || stringBytes[0] == 0x20 || stringBytes[stringBytes.length - 1] == 0x20
        ) 
            return false;
        
        return true;
    }

    /// @dev Checks that the position string is valid: alphanumeric with some special characters and spaces without leading or trailing space and under `MAX_POSITION_CHARACTERS` characters.
    /// @param stringBytes: Bytes array for the position string. 
    function validatePosition(bytes calldata stringBytes) internal pure returns (bool) {
        if (!validateStringBytes(stringBytes)) { revert NonValidCharacters(); }
        
        if(
            stringBytes.length == 0 || stringBytes.length > MAX_POSITION_CHARACTERS || stringBytes[0] == 0x20 || stringBytes[stringBytes.length - 1] == 0x20
        ) 
            return false;
        
        return true;
    }

    /// @dev Validates the other external properties of the Business Card
    /// @param cardProperties: External values for the Business Card.
    function validateOtherProperties(CardProperties calldata cardProperties) internal pure returns (bool) {
        if(
            bytes(cardProperties.twitterAccount).length < 15 &&
            bytes(cardProperties.telegramAccount).length < 32 &&
            bytes(cardProperties.telegramGroup).length < 32 &&
            ((cardProperties.discordAccount >= 10**17 && cardProperties.discordAccount < 10**18) || cardProperties.discordAccount == 0) &&
            bytes(cardProperties.discordGroup).length < 32 &&
            bytes(cardProperties.githubUsername).length < 39 &&
            bytes(cardProperties.website).length < 50
        )
            return true;
        
        return false;
    }

    /// @dev Validates that string contains valid characters, alphanumerical and some special symbols.
    /// @param stringBytes: Bytes array for the string to be validated.
    /// @return bool: Whehter the string is valid. 
    function validateStringBytes(bytes calldata stringBytes) internal pure returns (bool) {
        bytes1 lastChar = stringBytes[0];

        for(uint i; i < stringBytes.length; ){
            bytes1 char = stringBytes[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continuous spaces

            if(
                !(char >= 0x20 && char <= 0x3F) &&  // Special characters and numbers
                !(char >= 0x41 && char <= 0x5A) &&  // A-Z
                !(char >= 0x61 && char <= 0x7A)  // a-z
            )
                return false;

            lastChar = char;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /// @dev Converts a string to lowercase.
    /// @param str: String to be converted into lowercase.
    /// @return string: String in lowercase.
    function toLower(string memory str) internal pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; ++i) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
