const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Comprehensive deployment script for all Superstar Avatar contracts
 * Handles upgradeable contracts using UUPS proxy pattern
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  
  if (!deployer) {
    throw new Error(
      "No deployer account found. Please set PRIVATE_KEY in your .env file.\n" +
      "Example: PRIVATE_KEY=your_private_key_without_0x_prefix"
    );
  }
  
  console.log("Deploying contracts with the account:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  const balanceInEth = ethers.formatEther(balance);
  console.log("Account balance:", balanceInEth, "MATIC");
  
  // Check if balance is sufficient (need at least 0.5 MATIC for all deployments)
  const minBalance = ethers.parseEther("0.5");
  if (balance < minBalance) {
    console.warn("\n⚠️  WARNING: Low balance detected!");
    console.warn(`   Current balance: ${balanceInEth} MATIC`);
    console.warn(`   Recommended: At least 0.5 MATIC for all contract deployments`);
    console.warn(`   Get testnet MATIC from: https://faucet.polygon.technology/`);
    console.warn("\n   Continuing anyway, but deployment may fail if balance is insufficient...\n");
  }

  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {}
  };

  // ============================================
  // Phase 1: Core Contracts (No Dependencies)
  // ============================================

  // 1. Deploy GoldfireToken (upgradeable)
  console.log("\n[1/12] Deploying GoldfireToken (upgradeable)...");
  const GoldfireToken = await ethers.getContractFactory("GoldfireToken");
  const goldfireToken = await upgrades.deployProxy(
    GoldfireToken,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await goldfireToken.waitForDeployment();
  const goldfireTokenAddress = await goldfireToken.getAddress();
  console.log("✓ GoldfireToken deployed to:", goldfireTokenAddress);
  deploymentInfo.contracts.GoldfireToken = goldfireTokenAddress;

  // 2. Deploy AdminRegistry (upgradeable)
  console.log("\n[2/12] Deploying AdminRegistry (upgradeable)...");
  const AdminRegistry = await ethers.getContractFactory("AdminRegistry");
  const adminRegistry = await upgrades.deployProxy(
    AdminRegistry,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await adminRegistry.waitForDeployment();
  const adminRegistryAddress = await adminRegistry.getAddress();
  console.log("✓ AdminRegistry deployed to:", adminRegistryAddress);
  deploymentInfo.contracts.AdminRegistry = adminRegistryAddress;

  // Add deployer as initial admin
  try {
    await adminRegistry.addAdmin(deployer.address);
    console.log("✓ Deployer added as admin");
  } catch (e) {
    console.log("⚠️  Could not add deployer as admin (may already be admin)");
  }

  // 3. Deploy EventProducer (upgradeable)
  console.log("\n[3/12] Deploying EventProducer (upgradeable)...");
  const EventProducer = await ethers.getContractFactory("EventProducer");
  const eventProducer = await upgrades.deployProxy(
    EventProducer,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await eventProducer.waitForDeployment();
  const eventProducerAddress = await eventProducer.getAddress();
  console.log("✓ EventProducer deployed to:", eventProducerAddress);
  deploymentInfo.contracts.EventProducer = eventProducerAddress;

  // 4. Deploy PowerVerification (upgradeable)
  console.log("\n[4/12] Deploying PowerVerification (upgradeable)...");
  const PowerVerification = await ethers.getContractFactory("PowerVerification");
  const powerVerification = await upgrades.deployProxy(
    PowerVerification,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await powerVerification.waitForDeployment();
  const powerVerificationAddress = await powerVerification.getAddress();
  console.log("✓ PowerVerification deployed to:", powerVerificationAddress);
  deploymentInfo.contracts.PowerVerification = powerVerificationAddress;

  // 5. Deploy ActivityScripts (upgradeable)
  console.log("\n[5/12] Deploying ActivityScripts (upgradeable)...");
  const ActivityScripts = await ethers.getContractFactory("ActivityScripts");
  const activityScripts = await upgrades.deployProxy(
    ActivityScripts,
    [],
    { initializer: "initialize", kind: "uups" }
  );
  await activityScripts.waitForDeployment();
  const activityScriptsAddress = await activityScripts.getAddress();
  console.log("✓ ActivityScripts deployed to:", activityScriptsAddress);
  deploymentInfo.contracts.ActivityScripts = activityScriptsAddress;

  // 6. Deploy SuperstarAvatarRegistry (non-upgradeable)
  console.log("\n[6/12] Deploying SuperstarAvatarRegistry (non-upgradeable)...");
  const SuperstarAvatarRegistry = await ethers.getContractFactory("SuperstarAvatarRegistry");
  const superstarAvatarRegistry = await SuperstarAvatarRegistry.deploy();
  await superstarAvatarRegistry.waitForDeployment();
  const superstarAvatarRegistryAddress = await superstarAvatarRegistry.getAddress();
  console.log("✓ SuperstarAvatarRegistry deployed to:", superstarAvatarRegistryAddress);
  deploymentInfo.contracts.SuperstarAvatarRegistry = superstarAvatarRegistryAddress;

  // ============================================
  // Phase 2: Dependent Contracts
  // ============================================

  // 7. Deploy EventListings (upgradeable, requires EventProducer)
  console.log("\n[7/12] Deploying EventListings (upgradeable)...");
  const EventListings = await ethers.getContractFactory("EventListings");
  const eventListings = await upgrades.deployProxy(
    EventListings,
    [eventProducerAddress],
    { initializer: "initialize", kind: "uups" }
  );
  await eventListings.waitForDeployment();
  const eventListingsAddress = await eventListings.getAddress();
  console.log("✓ EventListings deployed to:", eventListingsAddress);
  deploymentInfo.contracts.EventListings = eventListingsAddress;

  // 8. Deploy Ticketing (upgradeable, requires EventListings and EventProducer)
  console.log("\n[8/12] Deploying Ticketing (upgradeable)...");
  const Ticketing = await ethers.getContractFactory("Ticketing");
  const platformFeePercentage = 500; // 5%
  const ticketing = await upgrades.deployProxy(
    Ticketing,
    [eventListingsAddress, eventProducerAddress, platformFeePercentage, deployer.address],
    { initializer: "initialize", kind: "uups" }
  );
  await ticketing.waitForDeployment();
  const ticketingAddress = await ticketing.getAddress();
  console.log("✓ Ticketing deployed to:", ticketingAddress);
  deploymentInfo.contracts.Ticketing = ticketingAddress;

  // Authorize Ticketing in EventListings
  try {
    await eventListings.setAuthorizedContract(ticketingAddress, true);
    console.log("✓ Ticketing authorized in EventListings");
  } catch (e) {
    console.log("⚠️  Could not authorize Ticketing:", e.message);
  }

  // 9. Deploy HouseMembership (upgradeable, requires GoldfireToken, EventProducer, EventListings)
  console.log("\n[9/12] Deploying HouseMembership (upgradeable)...");
  const HouseMembership = await ethers.getContractFactory("HouseMembership");
  const houseMembership = await upgrades.deployProxy(
    HouseMembership,
    [goldfireTokenAddress, eventProducerAddress, eventListingsAddress],
    { initializer: "initialize", kind: "uups" }
  );
  await houseMembership.waitForDeployment();
  const houseMembershipAddress = await houseMembership.getAddress();
  console.log("✓ HouseMembership deployed to:", houseMembershipAddress);
  deploymentInfo.contracts.HouseMembership = houseMembershipAddress;

  // Authorize HouseMembership to mint Goldfire tokens
  try {
    await goldfireToken.setAuthorizedMinter(houseMembershipAddress, true);
    console.log("✓ HouseMembership authorized to mint Goldfire tokens");
  } catch (e) {
    console.log("⚠️  Could not authorize HouseMembership:", e.message);
  }

  // 10. Deploy AvatarRegistry (upgradeable)
  console.log("\n[10/12] Deploying AvatarRegistry (upgradeable)...");
  const AvatarRegistry = await ethers.getContractFactory("AvatarRegistry");
  const avatarRegistry = await upgrades.deployProxy(
    AvatarRegistry,
    [deployer.address],
    { initializer: "initialize", kind: "uups" }
  );
  await avatarRegistry.waitForDeployment();
  const avatarRegistryAddress = await avatarRegistry.getAddress();
  console.log("✓ AvatarRegistry deployed to:", avatarRegistryAddress);
  deploymentInfo.contracts.AvatarRegistry = avatarRegistryAddress;

  // ============================================
  // Phase 3: ERC-4337 Contracts (Optional)
  // ============================================

  const entryPointAddress = process.env.ENTRY_POINT_ADDRESS || "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
  
  if (entryPointAddress && entryPointAddress !== "0x0000000000000000000000000000000000000000") {
    // 11. Deploy SimpleAccountFactory (upgradeable, requires EntryPoint)
    console.log("\n[11/12] Deploying SimpleAccountFactory (upgradeable)...");
    const SimpleAccountFactory = await ethers.getContractFactory("SimpleAccountFactory");
    const accountFactory = await upgrades.deployProxy(
      SimpleAccountFactory,
      [entryPointAddress],
      { initializer: "initialize", kind: "uups" }
    );
    await accountFactory.waitForDeployment();
    const accountFactoryAddress = await accountFactory.getAddress();
    console.log("✓ SimpleAccountFactory deployed to:", accountFactoryAddress);
    deploymentInfo.contracts.SimpleAccountFactory = accountFactoryAddress;
    deploymentInfo.contracts.EntryPoint = entryPointAddress;

    // 12. Deploy GoldfirePaymaster (upgradeable, requires GoldfireToken, AdminRegistry, EntryPoint)
    console.log("\n[12/12] Deploying GoldfirePaymaster (upgradeable)...");
    const GoldfirePaymaster = await ethers.getContractFactory("GoldfirePaymaster");
    const goldfireToGasRate = ethers.parseEther("0.001"); // 1 GF = 0.001 ETH
    const paymaster = await upgrades.deployProxy(
      GoldfirePaymaster,
      [entryPointAddress, goldfireTokenAddress, adminRegistryAddress, goldfireToGasRate],
      { initializer: "initialize", kind: "uups" }
    );
    await paymaster.waitForDeployment();
    const paymasterAddress = await paymaster.getAddress();
    console.log("✓ GoldfirePaymaster deployed to:", paymasterAddress);
    deploymentInfo.contracts.GoldfirePaymaster = paymasterAddress;

    // Optional: Fund paymaster
    const initialFunding = process.env.PAYMASTER_INITIAL_FUNDING || "0";
    if (initialFunding !== "0") {
      try {
        const fundingAmount = ethers.parseEther(initialFunding);
        const tx = await paymaster.deposit({ value: fundingAmount });
        await tx.wait();
        console.log(`✓ Paymaster funded with ${initialFunding} MATIC`);
      } catch (e) {
        console.log("⚠️  Could not fund paymaster:", e.message);
      }
    }
  } else {
    console.log("\n⚠️  EntryPoint address not set. Skipping ERC-4337 contracts.");
    console.log("   Set ENTRY_POINT_ADDRESS in .env to deploy Account Factory and Paymaster.");
  }

  // ============================================
  // Post-Deployment Setup
  // ============================================

  // Authorize verifier for ActivityScripts
  try {
    await activityScripts.setVerifierAuthorization(deployer.address, true);
    console.log("\n✓ Deployer authorized as verifier for ActivityScripts");
  } catch (e) {
    console.log("\n⚠️  Could not authorize verifier:", e.message);
  }

  // Create initial achievements and badges
  console.log("\nCreating initial achievements and badges...");
  try {
    await superstarAvatarRegistry.createAchievement(
      "First Steps",
      "Complete your first activity script",
      "Milestone",
      50,
      1
    );
    await superstarAvatarRegistry.createAchievement(
      "Power Master",
      "Reach level 10 in any power",
      "Power",
      200,
      3
    );
    await superstarAvatarRegistry.createAchievement(
      "House Leader",
      "Create and lead a house",
      "Social",
      150,
      2
    );
    await superstarAvatarRegistry.createAchievement(
      "Superstar",
      "Achieve Superstar Avatar status",
      "Legendary",
      1000,
      5
    );

    await superstarAvatarRegistry.createBadge("Courage Badge", "Awarded for acts of courage", "ipfs://QmCourageBadge", 2);
    await superstarAvatarRegistry.createBadge("Creativity Badge", "Awarded for creative contributions", "ipfs://QmCreativityBadge", 2);
    await superstarAvatarRegistry.createBadge("Connection Badge", "Awarded for building meaningful connections", "ipfs://QmConnectionBadge", 2);
    await superstarAvatarRegistry.createBadge("Insight Badge", "Awarded for deep insights and wisdom", "ipfs://QmInsightBadge", 2);
    await superstarAvatarRegistry.createBadge("Kindness Badge", "Awarded for acts of kindness", "ipfs://QmKindnessBadge", 2);
    
    console.log("✓ Initial achievements and badges created");
  } catch (e) {
    console.log("⚠️  Could not create achievements/badges:", e.message);
  }

  // Save deployment addresses
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  let allDeployments = {};
  
  if (fs.existsSync(deploymentPath)) {
    allDeployments = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  }
  
  allDeployments[hre.network.name] = {
    ...allDeployments[hre.network.name],
    ...deploymentInfo.contracts,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(allDeployments, null, 2));

  console.log("\n" + "=".repeat(60));
  console.log("DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log(JSON.stringify(allDeployments[hre.network.name], null, 2));
  console.log("\n✓ Deployment info saved to deployment.json");

  console.log("\n" + "=".repeat(60));
  console.log("NEXT STEPS");
  console.log("=".repeat(60));
  console.log("1. Verify contracts on Polygonscan:");
  console.log(`   npm run verify:${hre.network.name}`);
  console.log("\n2. Update Flutter app with contract addresses:");
  console.log("   Edit lib/constants/app_constants.dart");
  console.log("\n3. Test contracts with your Flutter app");
  console.log("\n✅ Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

