import { utils } from "ethers";

export const MAX_NAME_CHARACTERS = 22;
export const MAX_POSITION_CHARACTERS = 32;

export const MAX_SUPPLY = 2000;
export const MINT_PRICE = utils.parseEther("0.01");
export const UPDATE_PRICE = utils.parseEther("0.002");
export const ORACLE_FEE = utils.parseEther("0.0005");

export const MAX_DCT_SUPPLY = utils.parseEther("2125556342");
export const DCT_AIRDROP = utils.parseEther("212555");
export const DCT_AIRDROP_SUPPLY = DCT_AIRDROP.mul(MAX_SUPPLY);

export const MIN_LISTING_PRICE= utils.parseEther("0.001");

export const MAXIMUM_MEETING_PARTICIPANTS = 10;
export const MINIMUM_TIME_TO_MEETING_START = 1;
export const MAXIMUM_TIME_TO_MEETING_START = 10;
export const MINIMUM_MEETING_DURATION = 1;
export const MAXIMUM_MEETING_DURATION = 10;
export const PRECISION = 1e6;
