import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Superstar Avatar';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Develop your social superpowers';

  // Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);

  // Power Colors
  static const Map<String, Color> powerColors = {
    'courage': Color(0xFFEF4444),
    'creativity': Color(0xFF8B5CF6),
    'connection': Color(0xFF3B82F6),
    'insight': Color(0xFF10B981),
    'kindness': Color(0xFFF59E0B),
  };

  // Goldfire Activity Type Colors (Phase 1 - Basic Activities)
  static const Map<String, Color> activityTypeColors = {
    'personalResources': Color(0xFF6366F1),  // Indigo
    'introductions': Color(0xFF3B82F6),      // Blue
    'dynamics': Color(0xFF8B5CF6),           // Purple
    'locales': Color(0xFF10B981),            // Green
    'mythicLens': Color(0xFFF59E0B),         // Amber
    'alchemy': Color(0xFFEF4444),            // Red
    'tales': Color(0xFF06B6D4),              // Cyan
  };

  // Activity Type Icons
  static const Map<String, String> activityTypeIcons = {
    'personalResources': '📋',
    'introductions': '👋',
    'dynamics': '⚡',
    'locales': '📍',
    'mythicLens': '🔮',
    'alchemy': '✨',
    'tales': '📖',
  };

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient powerGradient = LinearGradient(
    colors: [accentColor, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const String fontFamily = 'Inter';
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 32.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
  static const double borderRadiusXXL = 24.0;

  // Shadows
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Experience Requirements
  static const Map<int, int> levelExperienceRequirements = {
    1: 0,
    2: 100,
    3: 250,
    4: 450,
    5: 700,
    6: 1000,
    7: 1350,
    8: 1750,
    9: 2200,
    10: 2700,
  };

  // Blockchain Configuration
  static const String polygonRpcUrl = 'https://polygon-rpc.com';
  static const String polygonChainId = '137';
  static const String polygonExplorerUrl = 'https://polygonscan.com';
  
  // Smart Contract Addresses (to be updated after deployment)
  // For development/testing, use these placeholder addresses
  // After deployment, replace with actual contract addresses
  static const String powerVerificationContractAddress = '0x0000000000000000000000000000000000000000';
  static const String houseMembershipContractAddress = '0x0000000000000000000000000000000000000000';
  static const String activityScriptsContractAddress = '0x0000000000000000000000000000000000000000';
  static const String superstarAvatarRegistryContractAddress = '0x0000000000000000000000000000000000000000';
  static const String eventProducerContractAddress = '0x0000000000000000000000000000000000000000';
  static const String eventListingsContractAddress = '0x0000000000000000000000000000000000000000';
  static const String ticketingContractAddress = '0x0000000000000000000000000000000000000000';
  static const String avatarRegistryContractAddress = '0x0000000000000000000000000000000000000000';

  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String avatarDataKey = 'avatar_data';
  static const String walletDataKey = 'wallet_data';
  static const String houseDataKey = 'house_data';
  static const String activityDataKey = 'activity_data';

  // API Endpoints (for centralized components)
  static const String baseApiUrl = 'https://api.superstaravatar.com';
  static const String eventApiUrl = '$baseApiUrl/events';
  static const String activityApiUrl = '$baseApiUrl/activities';
  static const String houseApiUrl = '$baseApiUrl/houses';

  // Feature Flags
  static const bool enableBlockchainFeatures = true;
  static const bool enableKioskMode = true;
  static const bool enableActivityCreation = true;
  static const bool enableHouseSystem = true;

  // Validation Rules
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;
  static const int minActivityTitleLength = 5;
  static const int maxActivityTitleLength = 100;
  static const int minActivityDescriptionLength = 20;
  static const int maxActivityDescriptionLength = 1000;

  // Limits
  static const int maxHouseMembers = 12;
  static const int maxActivityParticipants = 20;
  static const int maxTagsPerActivity = 5;
  static const int maxActivitiesPerDay = 10;
  static const int maxVerificationsPerDay = 50;

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String blockchainErrorMessage = 'Blockchain transaction failed. Please try again.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  static const String permissionErrorMessage = 'Permission denied. Please check your settings.';
  static const String walletErrorMessage = 'Wallet connection failed. Please try again.';

  // Success Messages
  static const String powerLevelUpMessage = 'Congratulations! Your power has leveled up!';
  static const String activityCompletedMessage = 'Activity completed successfully!';
  static const String verificationSuccessMessage = 'Verification successful!';
  static const String superstarAvatarMessage = 'Congratulations! You are now a Superstar Avatar!';

  // Onboarding Messages
  static const List<String> onboardingTitles = [
    'Welcome to Superstar Avatar',
    'Develop Your Powers',
    'Join a House',
    'Complete Activities',
    'Become a Superstar',
  ];

  static const List<String> onboardingDescriptions = [
    'Transform your social experiences through gamification and community building.',
    'Master five key social aptitudes: Courage, Creativity, Connection, Insight, and Kindness.',
    'Join a house with like-minded individuals and support each other\'s growth.',
    'Complete activities to earn experience and develop your powers.',
    'Achieve Superstar Avatar status and inspire others on their journey.',
  ];
} 