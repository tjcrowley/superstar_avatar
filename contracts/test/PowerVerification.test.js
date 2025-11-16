const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PowerVerification", function () {
  let PowerVerification;
  let powerVerification;
  let owner;
  let user1;
  let user2;
  let user3;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    PowerVerification = await ethers.getContractFactory("PowerVerification");
    powerVerification = await PowerVerification.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await powerVerification.owner()).to.equal(owner.address);
    });

    it("Should have correct level requirements", async function () {
      const requirements = await powerVerification.levelRequirements(0);
      expect(requirements).to.equal(0);
      
      const level2Req = await powerVerification.levelRequirements(1);
      expect(level2Req).to.equal(100);
      
      const level10Req = await powerVerification.levelRequirements(9);
      expect(level10Req).to.equal(2700);
    });
  });

  describe("Power Verification", function () {
    const avatarId = "test-avatar-123";
    const powerType = 0; // Courage

    it("Should verify power and award experience", async function () {
      const experience = 100;
      const metadata = "Test verification";

      await expect(powerVerification.connect(user1).verifyPower(
        avatarId,
        powerType,
        experience,
        metadata
      )).to.emit(powerVerification, "PowerVerified")
        .withArgs(avatarId, powerType, experience, user1.address, 2, await time());

      const powerData = await powerVerification.getPowerData(avatarId, powerType);
      expect(powerData.level).to.equal(2);
      expect(powerData.experience).to.equal(experience);
      expect(powerData.isSuperstarAvatar).to.equal(false);
    });

    it("Should handle level progression correctly", async function () {
      // Add 100 experience (should reach level 2)
      await powerVerification.connect(user1).verifyPower(avatarId, powerType, 100, "");
      
      // Add 150 more experience (should reach level 3)
      await powerVerification.connect(user2).verifyPower(avatarId, powerType, 150, "");
      
      const powerData = await powerVerification.getPowerData(avatarId, powerType);
      expect(powerData.level).to.equal(3);
      expect(powerData.experience).to.equal(250);
    });

    it("Should prevent excessive experience per verification", async function () {
      await expect(
        powerVerification.connect(user1).verifyPower(avatarId, powerType, 1001, "")
      ).to.be.revertedWith("Experience cannot exceed 1000 per verification");
    });

    it("Should prevent zero experience", async function () {
      await expect(
        powerVerification.connect(user1).verifyPower(avatarId, powerType, 0, "")
      ).to.be.revertedWith("Experience must be greater than 0");
    });

    it("Should prevent invalid power type", async function () {
      await expect(
        powerVerification.connect(user1).verifyPower(avatarId, 5, 100, "")
      ).to.be.revertedWith("Invalid power type");
    });

    it("Should prevent empty avatar ID", async function () {
      await expect(
        powerVerification.connect(user1).verifyPower("", powerType, 100, "")
      ).to.be.revertedWith("Avatar ID cannot be empty");
    });
  });

  describe("Superstar Avatar Status", function () {
    const avatarId = "superstar-test";

    it("Should achieve Superstar Avatar when all powers reach level 10", async function () {
      // Add experience to reach level 10 for all powers
      const experienceNeeded = 2700; // Level 10 requirement
      
      for (let powerType = 0; powerType < 5; powerType++) {
        await powerVerification.connect(user1).verifyPower(
          avatarId,
          powerType,
          experienceNeeded,
          ""
        );
      }

      // Check if Superstar Avatar status is achieved
      const canBecome = await powerVerification.canBecomeSuperstarAvatar(avatarId);
      expect(canBecome).to.equal(true);

      // Check individual power data
      for (let powerType = 0; powerType < 5; powerType++) {
        const powerData = await powerVerification.getPowerData(avatarId, powerType);
        expect(powerData.level).to.equal(10);
        expect(powerData.isSuperstarAvatar).to.equal(true);
      }
    });

    it("Should not achieve Superstar Avatar if not all powers are max level", async function () {
      // Add experience to reach level 10 for only 4 powers
      const experienceNeeded = 2700;
      
      for (let powerType = 0; powerType < 4; powerType++) {
        await powerVerification.connect(user1).verifyPower(
          avatarId,
          powerType,
          experienceNeeded,
          ""
        );
      }

      const canBecome = await powerVerification.canBecomeSuperstarAvatar(avatarId);
      expect(canBecome).to.equal(false);
    });
  });

  describe("Data Retrieval", function () {
    const avatarId = "data-test";

    beforeEach(async function () {
      // Add some test data
      await powerVerification.connect(user1).verifyPower(avatarId, 0, 100, "");
      await powerVerification.connect(user2).verifyPower(avatarId, 1, 200, "");
      await powerVerification.connect(user3).verifyPower(avatarId, 2, 150, "");
    });

    it("Should return correct all power data", async function () {
      const allData = await powerVerification.getAllPowerData(avatarId);
      
      expect(allData.levels[0]).to.equal(2); // Courage level 2
      expect(allData.levels[1]).to.equal(3); // Creativity level 3
      expect(allData.levels[2]).to.equal(2); // Connection level 2
      expect(allData.levels[3]).to.equal(1); // Insight level 1
      expect(allData.levels[4]).to.equal(1); // Kindness level 1
      
      expect(allData.experiences[0]).to.equal(100);
      expect(allData.experiences[1]).to.equal(200);
      expect(allData.experiences[2]).to.equal(150);
      
      expect(allData.totalExp).to.equal(450);
    });

    it("Should return verification history", async function () {
      const history = await powerVerification.getVerificationHistory(avatarId, 0);
      expect(history.length).to.equal(1);
      expect(history[0].verifier).to.equal(user1.address);
      expect(history[0].experience).to.equal(100);
    });

    it("Should return verifier statistics", async function () {
      const stats = await powerVerification.getVerifierStats(user1.address);
      expect(stats.verificationCount).to.equal(1);
    });
  });

  describe("Level Calculation", function () {
    it("Should calculate levels correctly", async function () {
      expect(await powerVerification.calculateLevel(0)).to.equal(1);
      expect(await powerVerification.calculateLevel(50)).to.equal(1);
      expect(await powerVerification.calculateLevel(100)).to.equal(2);
      expect(await powerVerification.calculateLevel(250)).to.equal(3);
      expect(await powerVerification.calculateLevel(2700)).to.equal(10);
      expect(await powerVerification.calculateLevel(3000)).to.equal(10);
    });

    it("Should return correct experience for next level", async function () {
      expect(await powerVerification.getExperienceForNextLevel(1)).to.equal(100);
      expect(await powerVerification.getExperienceForNextLevel(5)).to.equal(1000);
      expect(await powerVerification.getExperienceForNextLevel(10)).to.equal(0);
    });

    it("Should prevent invalid level in getExperienceForNextLevel", async function () {
      await expect(
        powerVerification.getExperienceForNextLevel(0)
      ).to.be.revertedWith("Invalid level");
      
      await expect(
        powerVerification.getExperienceForNextLevel(11)
      ).to.be.revertedWith("Invalid level");
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to update level requirements", async function () {
      const newRequirements = [0, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800];
      
      await powerVerification.updateLevelRequirements(newRequirements);
      
      for (let i = 0; i < newRequirements.length; i++) {
        expect(await powerVerification.levelRequirements(i)).to.equal(newRequirements[i]);
      }
    });

    it("Should prevent non-owner from updating level requirements", async function () {
      const newRequirements = [0, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800];
      
      await expect(
        powerVerification.connect(user1).updateLevelRequirements(newRequirements)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should prevent invalid level requirements array length", async function () {
      const invalidRequirements = [0, 100, 200]; // Too short
      
      await expect(
        powerVerification.updateLevelRequirements(invalidRequirements)
      ).to.be.revertedWith("Must have exactly 10 level requirements");
    });

    it("Should allow owner to emergency reset avatar", async function () {
      const avatarId = "reset-test";
      
      // Add some data first
      await powerVerification.connect(user1).verifyPower(avatarId, 0, 100, "");
      
      // Reset
      await powerVerification.emergencyResetAvatar(avatarId);
      
      // Verify data is cleared
      const powerData = await powerVerification.getPowerData(avatarId, 0);
      expect(powerData.level).to.equal(0);
      expect(powerData.experience).to.equal(0);
    });

    it("Should prevent non-owner from emergency reset", async function () {
      await expect(
        powerVerification.connect(user1).emergencyResetAvatar("test")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Events", function () {
    it("Should emit PowerVerified event", async function () {
      await expect(
        powerVerification.connect(user1).verifyPower("test", 0, 100, "metadata")
      ).to.emit(powerVerification, "PowerVerified")
        .withArgs("test", 0, 100, user1.address, 2, await time());
    });

    it("Should emit LevelUp event when level increases", async function () {
      // First verification to level 2
      await powerVerification.connect(user1).verifyPower("test", 0, 100, "");
      
      // Second verification to level 3
      await expect(
        powerVerification.connect(user2).verifyPower("test", 0, 150, "")
      ).to.emit(powerVerification, "LevelUp")
        .withArgs("test", 0, 2, 3, await time());
    });

    it("Should emit SuperstarAvatarAchieved event", async function () {
      const avatarId = "event-test";
      const experienceNeeded = 2700;
      
      // Add experience to reach level 10 for all powers
      for (let powerType = 0; powerType < 5; powerType++) {
        await powerVerification.connect(user1).verifyPower(
          avatarId,
          powerType,
          experienceNeeded,
          ""
        );
      }

      // The last verification should trigger the event
      await expect(
        powerVerification.connect(user1).verifyPower(avatarId, 4, 1, "")
      ).to.emit(powerVerification, "SuperstarAvatarAchieved")
        .withArgs(avatarId, await time());
    });
  });
});

// Helper function to get current timestamp
async function time() {
  const blockNum = await ethers.provider.getBlockNumber();
  const block = await ethers.provider.getBlock(blockNum);
  return block.timestamp;
} 