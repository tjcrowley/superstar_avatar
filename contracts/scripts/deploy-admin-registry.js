const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  if (!deployer) {
    throw new Error(
      "No deployer account found. Please set PRIVATE_KEY in your .env file."
    );
  }
  
  console.log("Deploying AdminRegistry with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Deploy AdminRegistry
  console.log("\nDeploying AdminRegistry contract...");
  const AdminRegistry = await ethers.getContractFactory("AdminRegistry");
  const adminRegistry = await AdminRegistry.deploy();
  await adminRegistry.waitForDeployment();
  const adminRegistryAddress = await adminRegistry.getAddress();
  console.log("AdminRegistry deployed to:", adminRegistryAddress);
  
  // Deployer is automatically added as admin
  console.log("Deployer automatically added as admin:", deployer.address);
  
  // Save deployment info
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let existingDeployment = {};
  
  if (fs.existsSync(deploymentPath)) {
    existingDeployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }
  
  const networkName = hre.network.name;
  if (!existingDeployment[networkName]) {
    existingDeployment[networkName] = {};
  }
  
  existingDeployment[networkName].adminRegistry = {
    address: adminRegistryAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(existingDeployment, null, 2));
  console.log("\nDeployment info saved to deployment.json");
  
  console.log("\n✅ AdminRegistry deployment complete!");
  console.log("   Address:", adminRegistryAddress);
  console.log("   Initial Admin:", deployer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

