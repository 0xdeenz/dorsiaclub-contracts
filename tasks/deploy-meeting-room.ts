import { task, types } from "hardhat/config"

task("deploy:meeting-room", "Deploys the Meeting Room smart contract")
    .addParam<string>("businessCardAddress", "Address for the Business Card smart contract.")
    .addOptionalParam<boolean>("logs", "Print logs")
    .setAction(
        async (
            {
                businessCardAddress,
                logs
            },
            { ethers }
        ): Promise<any> => {
            const MeetingRoomFactory = await ethers.getContractFactory("MeetingRoom")

            const meetingRoom = await MeetingRoomFactory.deploy(businessCardAddress)
            
            await meetingRoom.deployed()

            if (logs) {
                console.log("MeetingRoom smart contract deployed to: ", meetingRoom.address)
            }

            return {
                meetingRoomAddress: meetingRoom.address
            }
        }
    )
