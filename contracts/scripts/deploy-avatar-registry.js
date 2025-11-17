const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying AvatarRegistry with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy AvatarRegistry as upgradeable proxy
  console.log("\nDeploying AvatarRegistry (upgradeable)...");
  const AvatarRegistry = await ethers.getContractFactory("AvatarRegistry");
  
  // Deploy as upgradeable proxy
  const avatarRegistry = await upgrades.deployProxy(
    AvatarRegistry,
    [deployer.address], // initialOwner
    { 
      initializer: "initialize",
      kind: "uups" // Use UUPS (Universal Upgradeable Proxy Standard)
    }
  );
  
  await avatarRegistry.waitForDeployment();
  const avatarRegistryAddress = await avatarRegistry.getAddress();
  console.log("AvatarRegistry (proxy) deployed to:", avatarRegistryAddress);

  // Get implementation address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(avatarRegistryAddress);
  console.log("AvatarRegistry (implementation) deployed to:", implementationAddress);

  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      AvatarRegistry: {
        proxy: avatarRegistryAddress,
        implementation: implementationAddress,
      }
    }
  };

  // Read existing deployment.json if it exists
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let allDeployments = {};
  if (fs.existsSync(deploymentPath)) {
    allDeployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }

  // Update with new deployment
  allDeployments[network.name] = {
    ...allDeployments[network.name],
    ...deploymentInfo.contracts,
  };

  // Write back to file
  fs.writeFileSync(deploymentPath, JSON.stringify(allDeployments, null, 2));
  console.log("\nDeployment info saved to deployment.json");

  console.log("\n=== Deployment Summary ===");
  console.log("AvatarRegistry Proxy:", avatarRegistryAddress);
  console.log("AvatarRegistry Implementation:", implementationAddress);
  console.log("\nTo upgrade this contract in the future, use:");
  console.log(`npx hardhat run scripts/upgrade-avatar-registry.js --network ${network.name}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

