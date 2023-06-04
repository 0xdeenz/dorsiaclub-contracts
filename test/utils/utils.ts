import { utils } from "ethers"

export const createCardCommitment = (cardId: number | string, salt: number | string): string  => {
    return utils.keccak256(
        utils.toUtf8Bytes(
            utils.solidityPack(
                ["uint256", "uint256"],
                [cardId, salt]
            )
        )
    )
}