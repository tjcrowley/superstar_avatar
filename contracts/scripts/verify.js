const { run } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const deploymentPath = path.join(__dirname, "..", "deployment.json");
  
  if (!fs.existsSync(deploymentPath)) {
    console.error("❌ deployment.json not found. Please deploy contracts first.");
    process.exit(1);
  }

  const deploymentInfo = require(deploymentPath);
  const contracts = deploymentInfo.contracts;
  const network = deploymentInfo.network;

  console.log(`\n🔍 Verifying contracts on ${network}...\n`);

  // Verify PowerVerification (no constructor args)
  if (contracts.PowerVerification) {
    try {
      await run("verify:verify", {
        address: contracts.PowerVerification,
        network: network,
      });
      console.log("✅ PowerVerification verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  PowerVerification already verified");
      } else {
        console.log("❌ PowerVerification verification failed:", error.message);
      }
    }
  }

  // Verify HouseMembership (no constructor args)
  if (contracts.HouseMembership) {
    try {
      await run("verify:verify", {
        address: contracts.HouseMembership,
        network: network,
      });
      console.log("✅ HouseMembership verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  HouseMembership already verified");
      } else {
        console.log("❌ HouseMembership verification failed:", error.message);
      }
    }
  }

  // Verify ActivityScripts (no constructor args)
  if (contracts.ActivityScripts) {
    try {
      await run("verify:verify", {
        address: contracts.ActivityScripts,
        network: network,
      });
      console.log("✅ ActivityScripts verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  ActivityScripts already verified");
      } else {
        console.log("❌ ActivityScripts verification failed:", error.message);
      }
    }
  }

  // Verify SuperstarAvatarRegistry (no constructor args)
  if (contracts.SuperstarAvatarRegistry) {
    try {
      await run("verify:verify", {
        address: contracts.SuperstarAvatarRegistry,
        network: network,
      });
      console.log("✅ SuperstarAvatarRegistry verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  SuperstarAvatarRegistry already verified");
      } else {
        console.log("❌ SuperstarAvatarRegistry verification failed:", error.message);
      }
    }
  }

  // Verify EventProducer (no constructor args)
  if (contracts.EventProducer) {
    try {
      await run("verify:verify", {
        address: contracts.EventProducer,
        network: network,
      });
      console.log("✅ EventProducer verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  EventProducer already verified");
      } else {
        console.log("❌ EventProducer verification failed:", error.message);
      }
    }
  }

  // Verify EventListings (with EventProducer address)
  if (contracts.EventListings && contracts.EventProducer) {
    try {
      await run("verify:verify", {
        address: contracts.EventListings,
        constructorArguments: [contracts.EventProducer],
        network: network,
      });
      console.log("✅ EventListings verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  EventListings already verified");
      } else {
        console.log("❌ EventListings verification failed:", error.message);
      }
    }
  }

  // Verify Ticketing (with constructor args)
  if (contracts.Ticketing && contracts.EventListings && contracts.EventProducer) {
    try {
      // Platform fee: 5% (500 basis points)
      const platformFeePercentage = 500;
      const feeRecipient = deploymentInfo.deployer;

      await run("verify:verify", {
        address: contracts.Ticketing,
        constructorArguments: [
          contracts.EventListings,
          contracts.EventProducer,
          platformFeePercentage,
          feeRecipient,
        ],
        network: network,
      });
      console.log("✅ Ticketing verified");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  Ticketing already verified");
      } else {
        console.log("❌ Ticketing verification failed:", error.message);
      }
    }
  }

  console.log("\n✨ Verification complete!");
  console.log(`\n📋 View your contracts on Polygonscan:`);
  if (network === "mumbai") {
    console.log(`   https://mumbai.polygonscan.com/address/${contracts.PowerVerification}`);
  } else if (network === "polygon") {
    console.log(`   https://polygonscan.com/address/${contracts.PowerVerification}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

