const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  
  console.log("Upgrading AvatarRegistry with the account:", deployer.address);
  console.log("Network:", network.name);

  // Read deployment info
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  if (!fs.existsSync(deploymentPath)) {
    throw new Error("deployment.json not found. Please deploy the contract first.");
  }

  const deployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const proxyAddress = deployments[network.name]?.AvatarRegistry?.proxy;

  if (!proxyAddress) {
    throw new Error(`AvatarRegistry proxy address not found for network ${network.name}`);
  }

  console.log("Proxy address:", proxyAddress);

  // Deploy new implementation
  console.log("\nDeploying new AvatarRegistry implementation...");
  const AvatarRegistry = await ethers.getContractFactory("AvatarRegistry");
  
  const upgraded = await upgrades.upgradeProxy(proxyAddress, AvatarRegistry);
  await upgraded.waitForDeployment();
  
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("AvatarRegistry upgraded!");
  console.log("Proxy address (unchanged):", proxyAddress);
  console.log("New implementation address:", implementationAddress);

  // Update deployment info
  deployments[network.name].AvatarRegistry.implementation = implementationAddress;
  deployments[network.name].AvatarRegistry.lastUpgraded = new Date().toISOString();
  
  fs.writeFileSync(deploymentPath, JSON.stringify(deployments, null, 2));
  console.log("\nDeployment info updated in deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

