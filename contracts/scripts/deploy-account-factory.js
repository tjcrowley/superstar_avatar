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
  
  console.log("Deploying SimpleAccountFactory with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Get EntryPoint address from environment or use a default
  // For Polygon, you can use a deployed EntryPoint or deploy your own
  const entryPointAddress = process.env.ENTRY_POINT_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (entryPointAddress === "0x0000000000000000000000000000000000000000") {
    console.warn("\n⚠️  WARNING: EntryPoint address not set!");
    console.warn("   Set ENTRY_POINT_ADDRESS in .env file");
    console.warn("   For Polygon, you may need to deploy EntryPoint first");
  }
  
  // Deploy SimpleAccountFactory
  console.log("\nDeploying SimpleAccountFactory contract...");
  console.log("EntryPoint address:", entryPointAddress);
  
  const SimpleAccountFactory = await ethers.getContractFactory("SimpleAccountFactory");
  const accountFactory = await SimpleAccountFactory.deploy(entryPointAddress);
  await accountFactory.waitForDeployment();
  const accountFactoryAddress = await accountFactory.getAddress();
  console.log("SimpleAccountFactory deployed to:", accountFactoryAddress);
  
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
  
  existingDeployment[networkName].accountFactory = {
    address: accountFactoryAddress,
    entryPoint: entryPointAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(existingDeployment, null, 2));
  console.log("\nDeployment info saved to deployment.json");
  
  console.log("\n✅ SimpleAccountFactory deployment complete!");
  console.log("   Address:", accountFactoryAddress);
  console.log("   EntryPoint:", entryPointAddress);
  console.log("\n⚠️  Note: You need to set accountImplementation after deploying account contract");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

