const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Check deployment status of contracts
 * 
 * Usage:
 *   npx hardhat run scripts/check-deployment.js --network amoy
 */
async function main() {
  const network = hre.network.name;
  
  console.log("=".repeat(60));
  console.log("Checking Deployment Status");
  console.log("=".repeat(60));
  console.log("Network:", network);
  console.log("");

  // Read deployment info
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  if (!fs.existsSync(deploymentPath)) {
    console.log("⚠️  deployment.json not found");
    console.log("   No contracts have been deployed yet.");
    console.log("   Run: npm run deploy:all:amoy");
    return;
  }

  const deployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  
  // Get contract addresses
  const contracts = deployments[network]?.contracts || deployments[network] || deployments;
  
  const contractList = [
    { name: "GoldfireToken", key: "GoldfireToken" },
    { name: "AdminRegistry", key: "AdminRegistry" },
    { name: "EventProducer", key: "EventProducer" },
    { name: "PowerVerification", key: "PowerVerification" },
    { name: "ActivityScripts", key: "ActivityScripts" },
    { name: "HouseMembership", key: "HouseMembership" },
    { name: "AvatarRegistry", key: "AvatarRegistry" },
    { name: "SimpleAccountFactory", key: "SimpleAccountFactory" },
    { name: "GoldfirePaymaster", key: "GoldfirePaymaster" },
  ];

  console.log("Contract Deployment Status:");
  console.log("-".repeat(60));

  for (const contract of contractList) {
    const address = contracts[contract.key];
    
    if (address) {
      // Check if contract exists on chain
      const code = await ethers.provider.getCode(address);
      if (code !== "0x") {
        console.log(`✓ ${contract.name.padEnd(25)} ${address}`);
      } else {
        console.log(`✗ ${contract.name.padEnd(25)} ${address} (not found on chain)`);
      }
    } else {
      console.log(`✗ ${contract.name.padEnd(25)} Not deployed`);
    }
  }

  console.log("");
  console.log("=".repeat(60));
  console.log("ERC-4337 Configuration:");
  console.log("-".repeat(60));
  
  const entryPoint = process.env.ENTRY_POINT_ADDRESS || "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
  console.log(`EntryPoint: ${entryPoint}`);
  
  const paymasterAddress = contracts.GoldfirePaymaster;
  if (paymasterAddress) {
    try {
      const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);
      const isEnabled = await paymaster.sponsorAvatarCreation();
      const avatarRegistry = await paymaster.avatarRegistry();
      const balance = await ethers.provider.getBalance(paymasterAddress);
      
      console.log("");
      console.log("Paymaster Status:");
      console.log(`  Address: ${paymasterAddress}`);
      console.log(`  Sponsorship Enabled: ${isEnabled}`);
      console.log(`  Avatar Registry: ${avatarRegistry || "Not set"}`);
      console.log(`  Balance: ${ethers.formatEther(balance)} MATIC`);
    } catch (e) {
      console.log(`  ⚠️  Could not read paymaster status: ${e.message}`);
    }
  } else {
    console.log("  ⚠️  Paymaster not deployed");
  }

  console.log("");
  console.log("=".repeat(60));
  console.log("Next Steps:");
  console.log("=".repeat(60));
  
  const missingContracts = contractList.filter(c => !contracts[c.key]);
  if (missingContracts.length > 0) {
    console.log("Missing contracts - Deploy them:");
    missingContracts.forEach(c => {
      console.log(`  - ${c.name}`);
    });
    console.log("");
    console.log("Run: npm run deploy:all:amoy");
  } else {
    console.log("All contracts deployed!");
    console.log("");
    
    if (paymasterAddress) {
      try {
        const paymaster = await ethers.getContractAt("GoldfirePaymaster", paymasterAddress);
        const isEnabled = await paymaster.sponsorAvatarCreation();
        
        if (!isEnabled) {
          console.log("Enable paymaster sponsorship:");
          console.log("  npx hardhat run scripts/setup-paymaster-sponsorship.js --network amoy");
        } else {
          console.log("✓ Paymaster sponsorship is enabled");
        }
      } catch (e) {
        console.log("⚠️  Paymaster may need to be upgraded");
        console.log("  npx hardhat run scripts/upgrade-paymaster.js --network amoy");
      }
    }
  }
  
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

