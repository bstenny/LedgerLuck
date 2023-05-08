async function main() {
    const coinFlip = await ethers.getContractFactory("CoinFlipGame");
 
    // Start deployment, returning a promise that resolves to a contract object
    const coinFlipDeploy = await coinFlip.deploy();   
    console.log("Contract deployed to address:", coinFlipDeploy.address);
 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });