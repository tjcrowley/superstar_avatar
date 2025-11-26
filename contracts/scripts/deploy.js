const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

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
  
  // Check if balance is sufficient (need at least 0.2 MATIC for all deployments)
  const minBalance = ethers.parseEther("0.2");
  if (balance < minBalance) {
    console.warn("\n⚠️  WARNING: Low balance detected!");
    console.warn(`   Current balance: ${balanceInEth} MATIC`);
    console.warn(`   Recommended: At least 0.2 MATIC for all contract deployments`);
    console.warn(`   Get testnet MATIC from: https://faucet.polygon.technology/`);
    console.warn("\n   Continuing anyway, but deployment may fail if balance is insufficient...\n");
  }

  // Deploy PowerVerification contract
  console.log("\nDeploying PowerVerification contract...");
  const PowerVerification = await ethers.getContractFactory("PowerVerification");
  const powerVerification = await PowerVerification.deploy();
  await powerVerification.waitForDeployment();
  const powerVerificationAddress = await powerVerification.getAddress();
  console.log("PowerVerification deployed to:", powerVerificationAddress);

  // Deploy HouseMembership contract
  console.log("\nDeploying HouseMembership contract...");
  const HouseMembership = await ethers.getContractFactory("HouseMembership");
  const houseMembership = await HouseMembership.deploy();
  await houseMembership.waitForDeployment();
  const houseMembershipAddress = await houseMembership.getAddress();
  console.log("HouseMembership deployed to:", houseMembershipAddress);

  // Deploy ActivityScripts contract
  console.log("\nDeploying ActivityScripts contract...");
  const ActivityScripts = await ethers.getContractFactory("ActivityScripts");
  const activityScripts = await ActivityScripts.deploy();
  await activityScripts.waitForDeployment();
  const activityScriptsAddress = await activityScripts.getAddress();
  console.log("ActivityScripts deployed to:", activityScriptsAddress);

  // Deploy SuperstarAvatarRegistry contract
  console.log("\nDeploying SuperstarAvatarRegistry contract...");
  const SuperstarAvatarRegistry = await ethers.getContractFactory("SuperstarAvatarRegistry");
  const superstarAvatarRegistry = await SuperstarAvatarRegistry.deploy();
  await superstarAvatarRegistry.waitForDeployment();
  const superstarAvatarRegistryAddress = await superstarAvatarRegistry.getAddress();
  console.log("SuperstarAvatarRegistry deployed to:", superstarAvatarRegistryAddress);

  // Deploy EventProducer contract
  console.log("\nDeploying EventProducer contract...");
  const EventProducer = await ethers.getContractFactory("EventProducer");
  const eventProducer = await EventProducer.deploy();
  await eventProducer.waitForDeployment();
  const eventProducerAddress = await eventProducer.getAddress();
  console.log("EventProducer deployed to:", eventProducerAddress);

  // Deploy EventListings contract (requires EventProducer address)
  console.log("\nDeploying EventListings contract...");
  const EventListings = await ethers.getContractFactory("EventListings");
  const eventListings = await EventListings.deploy(eventProducerAddress);
  await eventListings.waitForDeployment();
  const eventListingsAddress = await eventListings.getAddress();
  console.log("EventListings deployed to:", eventListingsAddress);

  // Deploy Ticketing contract (requires EventListings and EventProducer addresses)
  console.log("\nDeploying Ticketing contract...");
  const Ticketing = await ethers.getContractFactory("Ticketing");
  // Platform fee: 5% (500 basis points), fee recipient is deployer
  const platformFeePercentage = 500; // 5%
  const ticketing = await Ticketing.deploy(
    eventListingsAddress,
    eventProducerAddress,
    platformFeePercentage,
    deployer.address
  );
  await ticketing.waitForDeployment();
  const ticketingAddress = await ticketing.getAddress();
  console.log("Ticketing deployed to:", ticketingAddress);

  // Create some initial achievements
  console.log("\nCreating initial achievements...");
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

  // Create some initial badges
  console.log("\nCreating initial badges...");
  await superstarAvatarRegistry.createBadge(
    "Courage Badge",
    "Awarded for acts of courage",
    "ipfs://QmCourageBadge",
    2
  );

  await superstarAvatarRegistry.createBadge(
    "Creativity Badge",
    "Awarded for creative contributions",
    "ipfs://QmCreativityBadge",
    2
  );

  await superstarAvatarRegistry.createBadge(
    "Connection Badge",
    "Awarded for building meaningful connections",
    "ipfs://QmConnectionBadge",
    2
  );

  await superstarAvatarRegistry.createBadge(
    "Insight Badge",
    "Awarded for deep insights and wisdom",
    "ipfs://QmInsightBadge",
    2
  );

  await superstarAvatarRegistry.createBadge(
    "Kindness Badge",
    "Awarded for acts of kindness",
    "ipfs://QmKindnessBadge",
    2
  );

  // Authorize some verifiers for ActivityScripts
  console.log("\nAuthorizing verifiers...");
  await activityScripts.setVerifierAuthorization(deployer.address, true);

  // Create some sample activity scripts
  console.log("\nCreating sample activity scripts...");
  await activityScripts.createActivityScript(
    "Introduce Yourself",
    "Introduce yourself to the community",
    "Share your name, interests, and what brings you here",
    0, // Courage
    [1, 2], // Creativity, Connection
    25,
    1,
    0, // No time limit
    0, // Unlimited completions
    false, // No verification required
    '{"category": "social", "tags": ["introduction", "community"]}'
  );

  await activityScripts.createActivityScript(
    "Share a Story",
    "Share a personal story with the community",
    "Tell a story about a time you showed courage or helped someone",
    0, // Courage
    [1, 4], // Creativity, Insight
    50,
    2,
    0,
    0,
    true, // Requires verification
    '{"category": "storytelling", "tags": ["courage", "personal"]}'
  );

  await activityScripts.createActivityScript(
    "Help Someone",
    "Help another community member",
    "Offer assistance, advice, or support to someone in need",
    4, // Kindness
    [2, 3], // Connection, Insight
    75,
    3,
    0,
    0,
    true, // Requires verification
    '{"category": "helping", "tags": ["kindness", "support"]}'
  );

  // Save deployment addresses
  const deploymentInfo = {
    network: network.name,
    deployer: deployer.address,
    contracts: {
      PowerVerification: powerVerificationAddress,
      HouseMembership: houseMembershipAddress,
      ActivityScripts: activityScriptsAddress,
      SuperstarAvatarRegistry: superstarAvatarRegistryAddress,
      EventProducer: eventProducerAddress,
      EventListings: eventListingsAddress,
      Ticketing: ticketingAddress,
    },
    timestamp: new Date().toISOString(),
  };

  console.log("\nDeployment Summary:");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  // Save to file
  const fs = require("fs");
  fs.writeFileSync(
    "deployment.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("\nDeployment info saved to deployment.json");

  console.log("\nDeployment completed successfully!");
  console.log("\nNext steps:");
  console.log("1. Update your Flutter app with the contract addresses");
  console.log("2. Verify contracts on Polygonscan (if on testnet/mainnet)");
  console.log("3. Test the contracts with your Flutter app");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 