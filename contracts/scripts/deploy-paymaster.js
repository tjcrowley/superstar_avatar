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
  
  console.log("Deploying GoldfirePaymaster with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Get required addresses from environment or deployment.json
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let deploymentInfo = {};
  
  if (fs.existsSync(deploymentPath)) {
    deploymentInfo = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }
  
  const networkName = hre.network.name;
  const networkDeployment = deploymentInfo[networkName] || {};
  
  const entryPointAddress = process.env.ENTRY_POINT_ADDRESS || networkDeployment.entryPoint || "0x0000000000000000000000000000000000000000";
  const goldfireTokenAddress = networkDeployment.goldfireToken?.address || process.env.GOLDFIRE_TOKEN_ADDRESS || "0x0000000000000000000000000000000000000000";
  const adminRegistryAddress = networkDeployment.adminRegistry?.address || process.env.ADMIN_REGISTRY_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  // Conversion rate: 1 GF = 0.001 ETH (1e15 wei) by default
  // This means 1000 GF tokens = 1 MATIC
  const goldfireToGasRate = process.env.GOLDFIRE_TO_GAS_RATE || "1000000000000000";
  
  console.log("\nDeployment parameters:");
  console.log("  EntryPoint:", entryPointAddress);
  console.log("  GoldfireToken:", goldfireTokenAddress);
  console.log("  AdminRegistry:", adminRegistryAddress);
  console.log("  GoldfireToGasRate:", goldfireToGasRate);
  
  if (entryPointAddress === "0x0000000000000000000000000000000000000000" ||
      goldfireTokenAddress === "0x0000000000000000000000000000000000000000" ||
      adminRegistryAddress === "0x0000000000000000000000000000000000000000") {
    throw new Error("Missing required contract addresses. Deploy dependencies first.");
  }
  
  // Deploy GoldfirePaymaster
  console.log("\nDeploying GoldfirePaymaster contract...");
  
  const GoldfirePaymaster = await ethers.getContractFactory("GoldfirePaymaster");
  const paymaster = await GoldfirePaymaster.deploy(
    entryPointAddress,
    goldfireTokenAddress,
    adminRegistryAddress,
    goldfireToGasRate
  );
  await paymaster.waitForDeployment();
  const paymasterAddress = await paymaster.getAddress();
  console.log("GoldfirePaymaster deployed to:", paymasterAddress);
  
  // Save deployment info
  if (!deploymentInfo[networkName]) {
    deploymentInfo[networkName] = {};
  }
  
  deploymentInfo[networkName].paymaster = {
    address: paymasterAddress,
    entryPoint: entryPointAddress,
    goldfireToken: goldfireTokenAddress,
    adminRegistry: adminRegistryAddress,
    goldfireToGasRate: goldfireToGasRate,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
  console.log("\nDeployment info saved to deployment.json");
  
  console.log("\n✅ GoldfirePaymaster deployment complete!");
  console.log("   Address:", paymasterAddress);
  console.log("\n⚠️  Next steps:");
  console.log("   1. Fund the paymaster with native tokens for gasless transactions");
  console.log("   2. Add users to whitelist for initial setup");
  console.log("   3. Configure conversion rate if needed");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

