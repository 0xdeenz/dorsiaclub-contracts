import { time, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Signer } from "ethers"
import { ethers, run } from "hardhat";
import { describe } from "mocha";
import {
    MeetingRoom,
    MeetingRoom__factory
} from "../typechain-types";

describe("CardMaestro smart contract library", () => {
    let cardMaestro;
    
    let meetingRoom: MeetingRoom;

    let signers: Signer[];
    let accounts: string[];

    // Example cardName and cardProperties
    const firstToken = ['Patrick BATEMAN', ['Vice President', '', '', '', '']];
    const secondToken = ['Paul ALLEN', ['Vice President', '', '', '', '']];
    const thirdToken = ['David VAN PATTEN', ['Vice President', '', '', '',  '']];
    const fourthToken = ['Timothy BRYCE', ['Vice President', '', '', '']];

    // URI parameters
    const baseUri = 'https://gateway.pinata.cloud/ipfs/Qm';
    const defaultUri = 'bFp3rybuvZ7j9e4xB6WLedu8gvLcjbVqUrGUEugQWz9u';

    // Filler value, would be dynamically generated by the server oracle
    const tokenURI = 'Ur63bgQq3VWW9XsVviDGAFwYEZVs9AFWsTd56T9xCQmf'

    before(async () => {
        signers = await run("accounts")
        accounts = await Promise.all(signers.map((signer: Signer) => signer.getAddress()));

        const CardMaestroFactory = await ethers.getContractFactory("CardMaestro")

        const cardMaestro = await CardMaestroFactory.deploy()
        

        // define a couple cards
    })

    beforeEach(async () => {

    })

    describe("getWinningChanceAgainst", () => {
        it("do be working", () => {

        })

        it("do not be working", () => {
            expect(true).to.be.equal(false)
        })
    })

})