const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Upgrade GoldfirePaymaster contract to add new gasless avatar creation features
 * 
 * New features added:
 * - sponsorAvatarCreation flag
 * - setSponsorAvatarCreation() function
 * - setAvatarRegistry() function
 * - whitelistForAvatarCreation() function
 * - Updated validateAndPay() to auto-sponsor avatar creation
 * 
 * Usage:
 *   npx hardhat run scripts/upgrade-paymaster.js --network amoy
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  const network = hre.network.name;
  
  console.log("=".repeat(60));
  console.log("Upgrading GoldfirePaymaster");
  console.log("=".repeat(60));
  console.log("Network:", network);
  console.log("Deployer:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "MATIC");
  console.log("");

  // Read deployment info
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  if (!fs.existsSync(deploymentPath)) {
    throw new Error(
      "deployment.json not found. Please deploy the contract first.\n" +
      "Run: npm run deploy:all:amoy"
    );
  }

  const deployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  
  // Try different possible keys for the paymaster address
  let proxyAddress;
  if (deployments[network]?.GoldfirePaymaster) {
    proxyAddress = deployments[network].GoldfirePaymaster;
  } else if (deployments[network]?.contracts?.GoldfirePaymaster) {
    proxyAddress = deployments[network].contracts.GoldfirePaymaster;
  } else if (deployments.GoldfirePaymaster) {
    proxyAddress = deployments.GoldfirePaymaster;
  }

  if (!proxyAddress) {
    throw new Error(
      `GoldfirePaymaster proxy address not found for network ${network}.\n` +
      `Please check deployment.json or deploy the contract first.`
    );
  }

  console.log("Proxy address:", proxyAddress);
  console.log("");

  // Get current implementation address
  try {
    const currentImpl = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("Current implementation:", currentImpl);
  } catch (e) {
    console.warn("⚠️  Could not get current implementation address");
  }

  // Verify contract exists and is upgradeable
  const code = await ethers.provider.getCode(proxyAddress);
  if (code === "0x") {
    throw new Error(`No contract found at address ${proxyAddress}`);
  }

  console.log("");
  console.log("Deploying new GoldfirePaymaster implementation...");
  console.log("");

  // Deploy new implementation
  const GoldfirePaymaster = await ethers.getContractFactory("GoldfirePaymaster");
  
  try {
    const upgraded = await upgrades.upgradeProxy(proxyAddress, GoldfirePaymaster);
    await upgraded.waitForDeployment();
    
    const newImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    
    console.log("");
    console.log("=".repeat(60));
    console.log("✓ Upgrade Successful!");
    console.log("=".repeat(60));
    console.log("Proxy address (unchanged):", proxyAddress);
    console.log("New implementation address:", newImplementationAddress);
    console.log("");

    // Verify new functions are available
    console.log("Verifying new functions...");
    const paymaster = await ethers.getContractAt("GoldfirePaymaster", proxyAddress);
    
    try {
      const isEnabled = await paymaster.sponsorAvatarCreation();
      console.log("✓ sponsorAvatarCreation() - Available");
      console.log("  Current value:", isEnabled);
    } catch (e) {
      console.error("✗ sponsorAvatarCreation() - Not available:", e.message);
    }

    try {
      const avatarRegistry = await paymaster.avatarRegistry();
      console.log("✓ avatarRegistry() - Available");
      console.log("  Current value:", avatarRegistry);
    } catch (e) {
      console.error("✗ avatarRegistry() - Not available:", e.message);
    }

    // Update deployment info
    if (!deployments[network]) {
      deployments[network] = {};
    }
    if (!deployments[network].contracts) {
      deployments[network].contracts = {};
    }
    
    deployments[network].contracts.GoldfirePaymaster = proxyAddress;
    deployments[network].contracts.GoldfirePaymasterImplementation = newImplementationAddress;
    deployments[network].contracts.GoldfirePaymasterLastUpgraded = new Date().toISOString();
    
    fs.writeFileSync(deploymentPath, JSON.stringify(deployments, null, 2));
    console.log("");
    console.log("✓ Deployment info updated in deployment.json");
    console.log("");

    console.log("=".repeat(60));
    console.log("Next Steps:");
    console.log("=".repeat(60));
    console.log("1. Enable paymaster sponsorship:");
    console.log("   npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy");
    console.log("");
    console.log("2. Update Flutter app with contract addresses");
    console.log("3. Configure bundler (see QUICK_START_BUNDLER.md)");
    console.log("4. Test gasless avatar creation");
    console.log("");

  } catch (error) {
    console.error("");
    console.error("=".repeat(60));
    console.error("✗ Upgrade Failed!");
    console.error("=".repeat(60));
    console.error("Error:", error.message);
    console.error("");
    
    if (error.message.includes("not upgrade safe")) {
      console.error("This error means the contract changes violate upgrade safety rules.");
      console.error("Common issues:");
      console.error("  - Changed storage layout");
      console.error("  - Removed functions");
      console.error("  - Changed function signatures");
      console.error("");
      console.error("Please review the contract changes and ensure:");
      console.error("  - Storage variables are only appended (not removed/reordered)");
      console.error("  - Functions are only added (not removed)");
      console.error("  - Function signatures are unchanged");
    }
    
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

