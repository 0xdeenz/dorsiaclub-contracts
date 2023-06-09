import { task, types } from "hardhat/config"

task("deploy:business-card", "Deploys the Business Card smart contract")
    .addParam<string>("baseUri", "Base URI for all Business Cards.")
    .addParam<string>("defaultUri", "Default URI for unminted/unprocessed Business Cards.")
    .addParam<string>("oracleAddress", "Initial address for the oracle.")
    .addOptionalParam<boolean>("startSale", "Starts the sale after deployment", true, types.boolean)
    .addOptionalParam<boolean>("deployMarketplace", "Deploys and connects the Card Marketplace after deployment", true, types.boolean)
    .addOptionalParam<boolean>("logs", "Print logs")
    .setAction(
        async (
            {
                baseUri,
                defaultUri,
                oracleAddress,
                startSale,
                deployMarketplace,
                logs
            },
            { ethers }
        ): Promise<any> => {
            const BusinessCardFactory = await ethers.getContractFactory("BusinessCard")

            const businessCard = await BusinessCardFactory.deploy(baseUri, defaultUri, oracleAddress)
            
            await businessCard.deployed()

            const dctAddress = await businessCard.DCT()

            if (logs) {
                console.log("BusinessCard smart contract deployed to: ", businessCard.address)
                
                console.log("BusinessCard deployed DCT smart contract to: ", dctAddress)
            }

            if (startSale) {
                await businessCard.startSale()

                if (logs) {
                    console.log("Sale of Business Cards started")
                }
            }

            if (deployMarketplace) {
                const CardMarketplaceFactory = await ethers.getContractFactory("CardMarketplace")

                const cardMarketplace = await CardMarketplaceFactory.deploy(businessCard.address)
                
                await cardMarketplace.deployed()
                
                if (logs) {
                    console.log("CardMarketplace smart contract deployed to: ", cardMarketplace.address)
                }

                await businessCard.setMarketplace(cardMarketplace.address)

                await cardMarketplace.startMarketplace()

                if (logs) {
                    console.log("Card Marketplace connected to Business Card smart contract and started")
                }

                return {
                    businessCardAddress: businessCard.address,
                    dctAddress,
                    cardMarketplaceAddress: cardMarketplace.address
                }
            } else {
                return {
                    businessCardAddress: businessCard.address,
                    dctAddress
                }
            }
        }
    )
