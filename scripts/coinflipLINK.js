async function main() {
    const coinFlip = await ethers.getContractFactory("CoinFlipGameLINK");
 
    // Start deployment, returning a promise that resolves to a contract object
    const coinFlipLINKDeploy = await coinFlip.deploy("0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625", "0x779877A7B0D9E8603169DdbD7836e478b4624789", 1850);   
    console.log("Contract deployed to address:", coinFlipLINKDeploy.address);
 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });