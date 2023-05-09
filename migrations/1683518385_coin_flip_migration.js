var flipContract = artifacts.require("CoinFlipGame");

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(flipContract);
};
