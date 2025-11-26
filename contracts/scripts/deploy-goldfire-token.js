const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  if (!deployer) {
    throw new Error(
      "No deployer account found. Please set PRIVATE_KEY in your .env file."
    );
  }
  
  console.log("Deploying GoldfireToken with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Deploy GoldfireToken
  console.log("\nDeploying GoldfireToken contract...");
  const GoldfireToken = await ethers.getContractFactory("GoldfireToken");
  const goldfireToken = await GoldfireToken.deploy();
  await goldfireToken.waitForDeployment();
  const goldfireTokenAddress = await goldfireToken.getAddress();
  console.log("GoldfireToken deployed to:", goldfireTokenAddress);
  
  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    goldfireToken: {
      address: goldfireTokenAddress,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
    }
  };
  
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let existingDeployment = {};
  
  if (fs.existsSync(deploymentPath)) {
    existingDeployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }
  
  const networkName = hre.network.name;
  if (!existingDeployment[networkName]) {
    existingDeployment[networkName] = {};
  }
  
  existingDeployment[networkName].goldfireToken = {
    address: goldfireTokenAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(existingDeployment, null, 2));
  console.log("\nDeployment info saved to deployment.json");
  
  console.log("\n✅ GoldfireToken deployment complete!");
  console.log("   Address:", goldfireTokenAddress);
  console.log("   Name: Goldfire");
  console.log("   Symbol: GF");
  console.log("   Decimals: 18");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

