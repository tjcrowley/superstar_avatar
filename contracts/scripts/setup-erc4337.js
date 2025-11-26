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
  
  console.log("Setting up ERC-4337 with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Load deployment info
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let deploymentInfo = {};
  
  if (fs.existsSync(deploymentPath)) {
    deploymentInfo = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }
  
  const networkName = hre.network.name;
  const networkDeployment = deploymentInfo[networkName] || {};
  
  // Check required contracts
  const goldfireToken = networkDeployment.goldfireToken?.address;
  const adminRegistry = networkDeployment.adminRegistry?.address;
  const accountFactory = networkDeployment.accountFactory?.address;
  const paymaster = networkDeployment.paymaster?.address;
  const entryPoint = process.env.ENTRY_POINT_ADDRESS || networkDeployment.entryPoint;
  
  if (!goldfireToken || !adminRegistry) {
    throw new Error("GoldfireToken and AdminRegistry must be deployed first. Run deploy-goldfire-token.js and deploy-admin-registry.js");
  }
  
  console.log("\nERC-4337 Setup Configuration:");
  console.log("  GoldfireToken:", goldfireToken);
  console.log("  AdminRegistry:", adminRegistry);
  console.log("  EntryPoint:", entryPoint || "Not set");
  console.log("  AccountFactory:", accountFactory || "Not deployed");
  console.log("  Paymaster:", paymaster || "Not deployed");
  
  // Deploy AccountFactory if not deployed
  if (!accountFactory) {
    console.log("\n⚠️  AccountFactory not deployed. Run deploy-account-factory.js first.");
  }
  
  // Deploy Paymaster if not deployed
  if (!paymaster) {
    console.log("\n⚠️  Paymaster not deployed. Run deploy-paymaster.js first.");
  }
  
  if (!entryPoint || entryPoint === "0x0000000000000000000000000000000000000000") {
    console.log("\n⚠️  EntryPoint address not set!");
    console.log("   For Polygon, you can use:");
    console.log("   - Mainnet: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789");
    console.log("   - Amoy: Check Polygon documentation for testnet EntryPoint");
    console.log("   Or deploy your own EntryPoint contract");
  }
  
  // If all contracts are deployed, perform setup operations
  if (accountFactory && paymaster && entryPoint) {
    console.log("\nPerforming ERC-4337 setup operations...");
    
    // Get contract instances
    const Paymaster = await ethers.getContractFactory("GoldfirePaymaster");
    const paymasterContract = Paymaster.attach(paymaster);
    
    // Fund paymaster with initial native tokens (optional)
    const initialFunding = process.env.PAYMASTER_INITIAL_FUNDING || "0.1";
    if (initialFunding !== "0") {
      console.log(`\nFunding paymaster with ${initialFunding} MATIC...`);
      const fundingAmount = ethers.parseEther(initialFunding);
      const tx = await paymasterContract.deposit({ value: fundingAmount });
      await tx.wait();
      console.log("Paymaster funded:", tx.hash);
    }
    
    console.log("\n✅ ERC-4337 setup complete!");
    console.log("\nNext steps:");
    console.log("1. Add users to paymaster whitelist for gasless initial setup");
    console.log("2. Configure conversion rate in paymaster if needed");
    console.log("3. Update Flutter app with contract addresses");
  } else {
    console.log("\n⚠️  Complete contract deployment before running setup.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

