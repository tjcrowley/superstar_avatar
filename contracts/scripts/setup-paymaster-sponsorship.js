/**
 * Script to enable avatar creation sponsorship on the paymaster
 * 
 * Usage:
 *   npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy
 * 
 * Make sure to set PAYMASTER_ADDRESS in your .env file
 */

const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Setting up paymaster sponsorship with account:", deployer.address);

  let paymasterAddress = process.env.PAYMASTER_ADDRESS;
  
  // If not in .env, try to get from deployment.json
  if (!paymasterAddress) {
    const deploymentPath = path.join(__dirname, "..", "deployment.json");
    if (fs.existsSync(deploymentPath)) {
      const deployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
      const network = hre.network.name;
      
      // Try different possible keys
      if (deployments[network]?.GoldfirePaymaster) {
        paymasterAddress = deployments[network].GoldfirePaymaster;
      } else if (deployments[network]?.contracts?.GoldfirePaymaster) {
        paymasterAddress = deployments[network].contracts.GoldfirePaymaster;
      } else if (deployments.GoldfirePaymaster) {
        paymasterAddress = deployments.GoldfirePaymaster;
      }
    }
  }
  
  if (!paymasterAddress) {
    throw new Error(
      "PAYMASTER_ADDRESS not found. Please set it in .env file or ensure deployment.json exists.\n" +
      "Example: PAYMASTER_ADDRESS=0x..."
    );
  }

  // Get the paymaster contract
  const GoldfirePaymaster = await ethers.getContractFactory("GoldfirePaymaster");
  const paymaster = GoldfirePaymaster.attach(paymasterAddress);

  console.log("\n=== Paymaster Configuration ===");
  console.log("Paymaster address:", paymasterAddress);
  
  // Check current balance
  const balance = await ethers.provider.getBalance(paymasterAddress);
  console.log("Current balance:", ethers.formatEther(balance), "MATIC");

  // Check if sponsorship is enabled
  const avatarCreationEnabled = await paymaster.sponsorAvatarCreation();
  console.log("Avatar creation sponsorship enabled:", avatarCreationEnabled);

  const allTransactionsEnabled = await paymaster.sponsorAllTransactions();
  console.log("All transactions sponsorship enabled:", allTransactionsEnabled);

  // Enable all transactions sponsorship (recommended for full gasless experience)
  if (!allTransactionsEnabled) {
    console.log("\nEnabling all transactions sponsorship...");
    try {
      const tx = await paymaster.setSponsorAllTransactions(true);
      await tx.wait();
      console.log("✓ All transactions sponsorship enabled");
      console.log("  All users can now perform any transaction gaslessly!");
    } catch (e) {
      console.warn("⚠️  Could not enable all transactions sponsorship:", e.message);
      console.warn("  This function may not exist in the current paymaster version.");
      console.warn("  Please upgrade the paymaster first: npm run upgrade:paymaster:amoy");
    }
  } else {
    console.log("✓ All transactions sponsorship already enabled");
  }

  // Enable avatar creation sponsorship (fallback if all transactions not available)
  if (!avatarCreationEnabled) {
    console.log("\nEnabling avatar creation sponsorship...");
    const tx = await paymaster.setSponsorAvatarCreation(true);
    await tx.wait();
    console.log("✓ Avatar creation sponsorship enabled");
  } else {
    console.log("✓ Avatar creation sponsorship already enabled");
  }

  // Set avatar registry address (if not already set)
  const avatarRegistryAddress = process.env.AVATAR_REGISTRY_ADDRESS;
  if (avatarRegistryAddress) {
    const currentRegistry = await paymaster.avatarRegistry();
    if (currentRegistry === ethers.ZeroAddress || currentRegistry !== avatarRegistryAddress) {
      console.log("\nSetting avatar registry address...");
      const tx = await paymaster.setAvatarRegistry(avatarRegistryAddress);
      await tx.wait();
      console.log("✓ Avatar registry set to:", avatarRegistryAddress);
    } else {
      console.log("✓ Avatar registry already set");
    }
  }

  // Fund the paymaster (optional)
  const fundAmount = process.env.PAYMASTER_FUND_AMOUNT;
  if (fundAmount) {
    const amount = ethers.parseEther(fundAmount);
    console.log("\nFunding paymaster with", fundAmount, "MATIC...");
    const tx = await paymaster.deposit({ value: amount });
    await tx.wait();
    console.log("✓ Paymaster funded");
    
    const newBalance = await ethers.provider.getBalance(paymasterAddress);
    console.log("New balance:", ethers.formatEther(newBalance), "MATIC");
  }

  console.log("\n=== Setup Complete ===");
  if (allTransactionsEnabled || (await paymaster.sponsorAllTransactions())) {
    console.log("Paymaster is ready to sponsor ALL user transactions!");
    console.log("All users can now perform any blockchain action gaslessly.");
  } else {
    console.log("Paymaster is ready to sponsor avatar creation transactions!");
    console.log("Users can now create avatars gaslessly.");
  }
  console.log("\nNext steps:");
  console.log("1. Ensure bundler is configured (see BUNDLER_SETUP_GUIDE.md)");
  console.log("2. Users can now perform transactions gaslessly");
  console.log("3. Update Flutter app to use TransactionService for all transactions");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

