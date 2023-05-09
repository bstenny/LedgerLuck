/** @type import('hardhat/config').HardhatUserConfig */

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    arbgoerli: {
       url: API_URL,
       chainId: 421613,
       accounts: [`0x${PRIVATE_KEY}`]
    }
 },
};
