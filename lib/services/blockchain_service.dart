import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import '../constants/app_constants.dart';
import 'admin_service.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  late Web3Client _client;
  late Credentials _credentials;
  String? _walletAddress;
  bool _isInitialized = false;

  // Contract instances
  late DeployedContract _powerVerificationContract;
  late DeployedContract _houseMembershipContract;
  late DeployedContract _activityScriptsContract;
  late DeployedContract _superstarAvatarRegistryContract;
  late DeployedContract _avatarRegistryContract;

  // Contract ABIs (simplified versions - full ABIs should be loaded from files)
  static const String powerVerificationABI = '''
    [
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "powerType", "type": "uint8"},
          {"name": "experience", "type": "uint256"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "verifyPower",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "powerType", "type": "uint8"}
        ],
        "name": "getPowerData",
        "outputs": [
          {"name": "level", "type": "uint256"},
          {"name": "experience", "type": "uint256"},
          {"name": "lastUpdated", "type": "uint256"},
          {"name": "isSuperstarAvatar", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getAllPowerData",
        "outputs": [
          {"name": "levels", "type": "uint256[5]"},
          {"name": "experiences", "type": "uint256[5]"},
          {"name": "totalExp", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "canBecomeSuperstarAvatar",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String houseMembershipABI = '''
    [
      {
        "inputs": [
          {"name": "name", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "eventId", "type": "string"},
          {"name": "eventName", "type": "string"},
          {"name": "maxMembers", "type": "uint256"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "createHouse",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "avatarName", "type": "string"}
        ],
        "name": "joinHouse",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "avatarId", "type": "string"}
        ],
        "name": "leaveHouse",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "houseId", "type": "string"}],
        "name": "getHouse",
        "outputs": [
          {"name": "id", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "eventId", "type": "string"},
          {"name": "eventName", "type": "string"},
          {"name": "leader", "type": "address"},
          {"name": "memberCount", "type": "uint256"},
          {"name": "maxMembers", "type": "uint256"},
          {"name": "totalExperience", "type": "uint256"},
          {"name": "averageLevel", "type": "uint256"},
          {"name": "createdAt", "type": "uint256"},
          {"name": "isActive", "type": "bool"},
          {"name": "metadata", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getAvatarHouse",
        "outputs": [{"name": "houseId", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "title", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "experienceReward", "type": "uint256"}
        ],
        "name": "proposeHouseActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "activityId", "type": "string"},
          {"name": "inFavor", "type": "bool"}
        ],
        "name": "voteOnActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "activityId", "type": "string"}
        ],
        "name": "leaderApproveActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "houseId", "type": "string"},
          {"name": "activityId", "type": "string"},
          {"name": "avatarId", "type": "string"}
        ],
        "name": "completeActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "houseId", "type": "string"}],
        "name": "getPendingActivities",
        "outputs": [{"name": "pendingActivityIds", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "activityId", "type": "string"}],
        "name": "getPendingActivity",
        "outputs": [
          {"name": "activityId", "type": "string"},
          {"name": "title", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "experienceReward", "type": "uint256"},
          {"name": "proposer", "type": "address"},
          {"name": "createdAt", "type": "uint256"},
          {"name": "votesFor", "type": "uint256"},
          {"name": "votesAgainst", "type": "uint256"},
          {"name": "isApproved", "type": "bool"},
          {"name": "isRejected", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "activityId", "type": "string"}],
        "name": "getActivityVotes",
        "outputs": [
          {
            "components": [
              {"name": "voter", "type": "address"},
              {"name": "inFavor", "type": "bool"},
              {"name": "timestamp", "type": "uint256"}
            ],
            "name": "votes",
            "type": "tuple[]"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "activityId", "type": "string"},
          {"name": "voter", "type": "address"}
        ],
        "name": "checkHasVoted",
        "outputs": [{"name": "hasVotedOnActivity", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String activityScriptsABI = '''
    [
      {
        "inputs": [
          {"name": "title", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "instructions", "type": "string"},
          {"name": "activityType", "type": "uint8"},
          {"name": "primaryPower", "type": "uint8"},
          {"name": "secondaryPowers", "type": "uint8[]"},
          {"name": "experienceReward", "type": "uint256"},
          {"name": "difficulty", "type": "uint256"},
          {"name": "timeLimit", "type": "uint256"},
          {"name": "maxCompletions", "type": "uint256"},
          {"name": "requiresVerification", "type": "bool"},
          {"name": "metadata", "type": "string"},
          {"name": "authorId", "type": "string"},
          {"name": "decentralizedStorageRef", "type": "string"}
        ],
        "name": "createActivityScript",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "activityId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "proof", "type": "string"}
        ],
        "name": "completeActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "activityId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "approved", "type": "bool"},
          {"name": "adjustedExperience", "type": "uint256"}
        ],
        "name": "verifyActivity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "activityId", "type": "string"}],
        "name": "getActivityScript",
        "outputs": [
          {"name": "id", "type": "string"},
          {"name": "title", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "instructions", "type": "string"},
          {"name": "activityType", "type": "uint8"},
          {"name": "primaryPower", "type": "uint8"},
          {"name": "secondaryPowers", "type": "uint8[]"},
          {"name": "experienceReward", "type": "uint256"},
          {"name": "difficulty", "type": "uint256"},
          {"name": "timeLimit", "type": "uint256"},
          {"name": "maxCompletions", "type": "uint256"},
          {"name": "completedCount", "type": "uint256"},
          {"name": "createdAt", "type": "uint256"},
          {"name": "isActive", "type": "bool"},
          {"name": "requiresVerification", "type": "bool"},
          {"name": "metadata", "type": "string"},
          {"name": "authorId", "type": "string"},
          {"name": "decentralizedStorageRef", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "activityId", "type": "string"},
          {"name": "avatarId", "type": "string"}
        ],
        "name": "hasCompletedActivity",
        "outputs": [{"name": "completed", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "activityType", "type": "uint8"}],
        "name": "getActivitiesByType",
        "outputs": [{"name": "activityIds", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "getAllActivityIds",
        "outputs": [{"name": "activityIds", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "getActivityCount",
        "outputs": [{"name": "count", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "authorId", "type": "string"}],
        "name": "getActivitiesByAuthor",
        "outputs": [{"name": "activityIds", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "owner",
        "outputs": [{"name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String superstarAvatarRegistryABI = '''
    [
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "bio", "type": "string"},
          {"name": "powerLevels", "type": "uint256[5]"},
          {"name": "powerExperience", "type": "uint256[5]"},
          {"name": "totalExperience", "type": "uint256"}
        ],
        "name": "registerSuperstarAvatar",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "achievementId", "type": "string"}
        ],
        "name": "unlockAchievement",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "badgeId", "type": "string"}
        ],
        "name": "awardBadge",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getSuperstarAvatar",
        "outputs": [
          {"name": "id", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "bio", "type": "string"},
          {"name": "walletAddress", "type": "address"},
          {"name": "totalExperience", "type": "uint256"},
          {"name": "powerLevels", "type": "uint256[5]"},
          {"name": "powerExperience", "type": "uint256[5]"},
          {"name": "achievedAt", "type": "uint256"},
          {"name": "lastActive", "type": "uint256"},
          {"name": "achievements", "type": "string[]"},
          {"name": "badges", "type": "string[]"},
          {"name": "isActive", "type": "bool"},
          {"name": "metadata", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String avatarRegistryABI = '''
    [
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "bio", "type": "string"},
          {"name": "imageUri", "type": "string"},
          {"name": "houseId", "type": "string"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "createAvatar",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "bio", "type": "string"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "updateAvatar",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "newImageUri", "type": "string"}
        ],
        "name": "updateAvatarImage",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getAvatar",
        "outputs": [
          {
            "components": [
              {"name": "id", "type": "string"},
              {"name": "name", "type": "string"},
              {"name": "bio", "type": "string"},
              {"name": "imageUri", "type": "string"},
              {"name": "walletAddress", "type": "address"},
              {"name": "createdAt", "type": "uint256"},
              {"name": "updatedAt", "type": "uint256"},
              {"name": "isActive", "type": "bool"},
              {"name": "isPrimary", "type": "bool"},
              {"name": "houseId", "type": "string"},
              {"name": "metadata", "type": "string"}
            ],
            "name": "",
            "type": "tuple"
          }
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "walletAddress", "type": "address"}],
        "name": "getAvatarIdsByAddress",
        "outputs": [{"name": "", "type": "string[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "walletAddress", "type": "address"}],
        "name": "getPrimaryAvatarIdByAddress",
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "walletAddress", "type": "address"}],
        "name": "getAvatarCountByAddress",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "avatarExistsCheck",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Web3 client with timeout
      _client = Web3Client(
        AppConstants.polygonRpcUrl,
        http.Client(),
      );

      // Initialize contract instances only if addresses are valid (not placeholder)
      final zeroAddress = '0x0000000000000000000000000000000000000000';
      
      if (AppConstants.powerVerificationContractAddress != zeroAddress) {
        _powerVerificationContract = DeployedContract(
          ContractAbi.fromJson(powerVerificationABI, 'PowerVerification'),
          EthereumAddress.fromHex(AppConstants.powerVerificationContractAddress),
        );
      }

      if (AppConstants.houseMembershipContractAddress != zeroAddress) {
        _houseMembershipContract = DeployedContract(
          ContractAbi.fromJson(houseMembershipABI, 'HouseMembership'),
          EthereumAddress.fromHex(AppConstants.houseMembershipContractAddress),
        );
      }

      if (AppConstants.activityScriptsContractAddress != zeroAddress) {
        _activityScriptsContract = DeployedContract(
          ContractAbi.fromJson(activityScriptsABI, 'ActivityScripts'),
          EthereumAddress.fromHex(AppConstants.activityScriptsContractAddress),
        );
      }

      if (AppConstants.superstarAvatarRegistryContractAddress != zeroAddress) {
        _superstarAvatarRegistryContract = DeployedContract(
          ContractAbi.fromJson(superstarAvatarRegistryABI, 'SuperstarAvatarRegistry'),
          EthereumAddress.fromHex(AppConstants.superstarAvatarRegistryContractAddress),
        );
      }

      if (AppConstants.avatarRegistryContractAddress != zeroAddress) {
        try {
          _avatarRegistryContract = DeployedContract(
            ContractAbi.fromJson(avatarRegistryABI, 'AvatarRegistry'),
            EthereumAddress.fromHex(AppConstants.avatarRegistryContractAddress),
          );
        } catch (e) {
          debugPrint('Warning: Failed to initialize AvatarRegistry contract: $e');
        }
      }

      _isInitialized = true;
      debugPrint('BlockchainService initialized successfully');
      
      // Note: Wallet credentials are not persisted for security reasons
      // Users must re-import their wallet on app restart
    } catch (e, stack) {
      debugPrint('Error initializing blockchain service: $e');
      debugPrint('Stack: $stack');
      // Don't throw - allow app to continue with limited functionality
      // The service can be re-initialized later when needed
      _isInitialized = false;
    }
  }

  Future<String> createWallet({bool requestInitialFunding = true}) async {
    try {
      final mnemonic = bip39.generateMnemonic();
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = seed.sublist(0, 32);
      
      _credentials = EthPrivateKey(privateKey);
      _walletAddress = _credentials.address.hex;
      
      // Request initial funding if enabled (for testnet)
      if (requestInitialFunding && _walletAddress != null) {
        // This will be handled by the wallet provider after wallet creation
        // to avoid blocking the wallet creation process
      }
      
      return mnemonic;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<void> importWallet(String mnemonic) async {
    try {
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = seed.sublist(0, 32);
      
      _credentials = EthPrivateKey(privateKey);
      _walletAddress = _credentials.address.hex;
    } catch (e) {
      throw Exception('Failed to import wallet: $e');
    }
  }

  String? get walletAddress => _walletAddress;

  bool get isWalletConnected => _walletAddress != null;
  
  Web3Client get client {
    if (!_isInitialized) {
      throw Exception('BlockchainService not initialized. Call initialize() first.');
    }
    return _client;
  }
  
  Credentials get credentials {
    if (!isWalletConnected) {
      throw Exception('Wallet not connected. Import or create a wallet first.');
    }
    return _credentials;
  }

  Future<BigInt> getBalance() async {
    if (!isWalletConnected) throw Exception('Wallet not connected');
    
    try {
      final address = EthereumAddress.fromHex(_walletAddress!);
      final balance = await _client.getBalance(address);
      return balance.getInWei;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  // Power Verification Methods
  Future<String> verifyPower({
    required String avatarId,
    required int powerType,
    required int experience,
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _powerVerificationContract.function('verifyPower');
      final params = [
        avatarId,
        BigInt.from(powerType),
        BigInt.from(experience),
        metadata,
      ];

      final transaction = Transaction.callContract(
        contract: _powerVerificationContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to verify power: $e');
    }
  }

  Future<Map<String, dynamic>> getPowerData(String avatarId, int powerType) async {
    try {
      final function = _powerVerificationContract.function('getPowerData');
      final params = [avatarId, BigInt.from(powerType)];

      final result = await _client.call(
        contract: _powerVerificationContract,
        function: function,
        params: params,
      );

      return {
        'level': (result[0] as BigInt).toInt(),
        'experience': (result[1] as BigInt).toInt(),
        'lastUpdated': (result[2] as BigInt).toInt(),
        'isSuperstarAvatar': result[3] as bool,
      };
    } catch (e) {
      throw Exception('Failed to get power data: $e');
    }
  }

  Future<Map<String, dynamic>> getAllPowerData(String avatarId) async {
    try {
      final function = _powerVerificationContract.function('getAllPowerData');
      final params = [avatarId];

      final result = await _client.call(
        contract: _powerVerificationContract,
        function: function,
        params: params,
      );

      final levels = (result[0] as List<BigInt>).map((e) => e.toInt()).toList();
      final experiences = (result[1] as List<BigInt>).map((e) => e.toInt()).toList();
      final totalExp = (result[2] as BigInt).toInt();

      return {
        'levels': levels,
        'experiences': experiences,
        'totalExperience': totalExp,
      };
    } catch (e) {
      throw Exception('Failed to get all power data: $e');
    }
  }

  Future<bool> canBecomeSuperstarAvatar(String avatarId) async {
    try {
      final function = _powerVerificationContract.function('canBecomeSuperstarAvatar');
      final params = [avatarId];

      final result = await _client.call(
        contract: _powerVerificationContract,
        function: function,
        params: params,
      );

      return result.first as bool;
    } catch (e) {
      return false;
    }
  }

  // House Membership Methods
  Future<String> createHouse({
    required String name,
    required String description,
    required String eventId,
    required String eventName,
    required int maxMembers,
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('createHouse');
      final params = [
        name,
        description,
        eventId,
        eventName,
        BigInt.from(maxMembers),
        metadata,
      ];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to create house: $e');
    }
  }

  Future<String> joinHouse({
    required String houseId,
    required String avatarId,
    required String avatarName,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('joinHouse');
      final params = [houseId, avatarId, avatarName];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to join house: $e');
    }
  }

  Future<String> leaveHouse({
    required String houseId,
    required String avatarId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('leaveHouse');
      final params = [houseId, avatarId];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to leave house: $e');
    }
  }

  Future<Map<String, dynamic>?> getHouse(String houseId) async {
    try {
      final function = _houseMembershipContract.function('getHouse');
      final params = [houseId];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      return {
        'id': result[0] as String,
        'name': result[1] as String,
        'description': result[2] as String,
        'eventId': result[3] as String,
        'eventName': result[4] as String,
        'leader': result[5] as String,
        'memberCount': (result[6] as BigInt).toInt(),
        'maxMembers': (result[7] as BigInt).toInt(),
        'totalExperience': (result[8] as BigInt).toInt(),
        'averageLevel': (result[9] as BigInt).toInt(),
        'createdAt': (result[10] as BigInt).toInt(),
        'isActive': result[11] as bool,
        'metadata': result[12] as String,
      };
    } catch (e) {
      return null;
    }
  }

  // House Activity Voting Methods
  
  /// Propose a new house activity (requires voting if multiple members)
  Future<String> proposeHouseActivity({
    required String houseId,
    required String title,
    required String description,
    required int experienceReward,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('proposeHouseActivity');
      final params = [
        houseId,
        title,
        description,
        BigInt.from(experienceReward),
      ];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to propose house activity: $e');
    }
  }

  /// Vote on a pending activity
  Future<String> voteOnActivity({
    required String houseId,
    required String activityId,
    required bool inFavor,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('voteOnActivity');
      final params = [houseId, activityId, inFavor];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to vote on activity: $e');
    }
  }

  /// Leader can directly approve activity (bypass voting)
  Future<String> leaderApproveActivity({
    required String houseId,
    required String activityId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('leaderApproveActivity');
      final params = [houseId, activityId];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to approve activity: $e');
    }
  }

  /// Complete a house activity (mints Goldfire tokens)
  Future<String> completeHouseActivity({
    required String houseId,
    required String activityId,
    required String avatarId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _houseMembershipContract.function('completeActivity');
      final params = [houseId, activityId, avatarId];

      final transaction = Transaction.callContract(
        contract: _houseMembershipContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to complete house activity: $e');
    }
  }

  /// Get pending activities for a house
  Future<List<String>> getPendingActivities(String houseId) async {
    try {
      final function = _houseMembershipContract.function('getPendingActivities');
      final params = [houseId];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      return (result[0] as List).map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting pending activities: $e');
      return [];
    }
  }

  /// Get pending activity details
  Future<Map<String, dynamic>?> getPendingActivity(String activityId) async {
    try {
      final function = _houseMembershipContract.function('getPendingActivity');
      final params = [activityId];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      return {
        'activityId': result[0] as String,
        'title': result[1] as String,
        'description': result[2] as String,
        'experienceReward': (result[3] as BigInt).toInt(),
        'proposer': result[4] as String,
        'createdAt': (result[5] as BigInt).toInt(),
        'votesFor': (result[6] as BigInt).toInt(),
        'votesAgainst': (result[7] as BigInt).toInt(),
        'isApproved': result[8] as bool,
        'isRejected': result[9] as bool,
      };
    } catch (e) {
      debugPrint('Error getting pending activity: $e');
      return null;
    }
  }

  /// Get votes for an activity
  Future<List<Map<String, dynamic>>> getActivityVotes(String activityId) async {
    try {
      final function = _houseMembershipContract.function('getActivityVotes');
      final params = [activityId];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      final votes = result[0] as List;
      return votes.map((vote) => {
        'voter': (vote[0] as EthereumAddress).hex,
        'inFavor': vote[1] as bool,
        'timestamp': (vote[2] as BigInt).toInt(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting activity votes: $e');
      return [];
    }
  }

  /// Check if address has voted on activity
  Future<bool> checkHasVoted({
    required String activityId,
    required String voterAddress,
  }) async {
    try {
      final function = _houseMembershipContract.function('checkHasVoted');
      final params = [
        activityId,
        EthereumAddress.fromHex(voterAddress),
      ];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking vote status: $e');
      return false;
    }
  }

  Future<String?> getAvatarHouse(String avatarId) async {
    try {
      final function = _houseMembershipContract.function('getAvatarHouse');
      final params = [avatarId];

      final result = await _client.call(
        contract: _houseMembershipContract,
        function: function,
        params: params,
      );

      return result.first as String;
    } catch (e) {
      return null;
    }
  }

  // Activity Scripts Methods (Goldfire Phase 1 Integration)
  /// Create a new activity script with ActivityType and Power associations
  Future<String> createActivityScript({
    required String title,
    required String description,
    required String instructions,
    required int activityType,  // ActivityType enum index (0-6)
    required int primaryPower,  // PowerType enum index (0-4)
    required List<int> secondaryPowers,  // PowerType enum indices (max 4)
    required int experienceReward,
    required int difficulty,  // 1-10
    required int timeLimit,  // seconds, 0 for no limit
    required int maxCompletions,  // 0 for unlimited
    required bool requiresVerification,
    required String metadata,  // JSON string for Tales, narrative, etc.
    required String authorId,  // Avatar ID or House ID
    required String decentralizedStorageRef,  // IPFS hash
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _activityScriptsContract.function('createActivityScript');
      final params = [
        title,
        description,
        instructions,
        BigInt.from(activityType),  // ActivityType enum
        BigInt.from(primaryPower),  // PowerType enum
        secondaryPowers.map((p) => BigInt.from(p)).toList(),  // PowerType[] enum array
        BigInt.from(experienceReward),
        BigInt.from(difficulty),
        BigInt.from(timeLimit),
        BigInt.from(maxCompletions),
        requiresVerification,
        metadata,
        authorId,
        decentralizedStorageRef,
      ];

      final transaction = Transaction.callContract(
        contract: _activityScriptsContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to create activity script: $e');
    }
  }

  Future<String> completeActivity({
    required String activityId,
    required String avatarId,
    String proof = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _activityScriptsContract.function('completeActivity');
      final params = [activityId, avatarId, proof];

      final transaction = Transaction.callContract(
        contract: _activityScriptsContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to complete activity: $e');
    }
  }

  Future<String> verifyActivity({
    required String activityId,
    required String avatarId,
    required bool approved,
    int adjustedExperience = 0,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _activityScriptsContract.function('verifyActivity');
      final params = [
        activityId,
        avatarId,
        approved,
        BigInt.from(adjustedExperience),
      ];

      final transaction = Transaction.callContract(
        contract: _activityScriptsContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to verify activity: $e');
    }
  }

  Future<bool> hasCompletedActivity(String activityId, String avatarId) async {
    try {
      final function = _activityScriptsContract.function('hasCompletedActivity');
      final params = [activityId, avatarId];

      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: params,
      );

      return result.first as bool;
    } catch (e) {
      return false;
    }
  }

  /// Get activity script by ID
  Future<Map<String, dynamic>?> getActivityScript(String activityId) async {
    try {
      final function = _activityScriptsContract.function('getActivityScript');
      final params = [activityId];

      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: params,
      );

      // Parse the result according to the contract return structure
      return {
        'id': result[0] as String,
        'title': result[1] as String,
        'description': result[2] as String,
        'instructions': result[3] as String,
        'activityType': (result[4] as BigInt).toInt(),
        'primaryPower': (result[5] as BigInt).toInt(),
        'secondaryPowers': (result[6] as List<BigInt>).map((e) => e.toInt()).toList(),
        'experienceReward': (result[7] as BigInt).toInt(),
        'difficulty': (result[8] as BigInt).toInt(),
        'timeLimit': (result[9] as BigInt).toInt(),
        'maxCompletions': (result[10] as BigInt).toInt(),
        'completedCount': (result[11] as BigInt).toInt(),
        'createdAt': (result[12] as BigInt).toInt(),
        'isActive': result[13] as bool,
        'requiresVerification': result[14] as bool,
        'metadata': result[15] as String,
        'authorId': result[16] as String,
        'decentralizedStorageRef': result[17] as String,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get activity IDs by type
  Future<List<String>> getActivitiesByType(int activityType) async {
    try {
      final function = _activityScriptsContract.function('getActivitiesByType');
      final params = [BigInt.from(activityType)];

      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: params,
      );

      return (result[0] as List<dynamic>).map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all activities by fetching from all activity types
  /// Now uses the contract's getAllActivityIds() function for better performance
  Future<List<String>> getAllActivityIds() async {
    try {
      final function = _activityScriptsContract.function('getAllActivityIds');
      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: [],
      );

      return (result[0] as List<dynamic>).map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting all activity IDs: $e');
      // Fallback to fetching by type if direct call fails
      try {
        final allActivityIds = <String>{};
        for (int activityType = 0; activityType < 7; activityType++) {
          final activityIds = await getActivitiesByType(activityType);
          allActivityIds.addAll(activityIds);
        }
        return allActivityIds.toList();
      } catch (fallbackError) {
        debugPrint('Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get activities by author
  Future<List<String>> getActivitiesByAuthor(String authorId) async {
    try {
      final function = _activityScriptsContract.function('getActivitiesByAuthor');
      final params = [authorId];

      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: params,
      );

      return (result[0] as List<dynamic>).map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting activities by author: $e');
      return [];
    }
  }

  /// Get total activity count
  Future<int> getActivityCount() async {
    try {
      final function = _activityScriptsContract.function('getActivityCount');
      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: [],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      debugPrint('Error getting activity count: $e');
      return 0;
    }
  }

  /// Check if the current wallet is the contract owner (admin)
  Future<bool> isContractOwner() async {
    try {
      if (!isWalletConnected) return false;
      
      final function = _activityScriptsContract.function('owner');
      final result = await _client.call(
        contract: _activityScriptsContract,
        function: function,
        params: [],
      );
      
      final ownerAddress = (result[0] as EthereumAddress).hex;
      return ownerAddress.toLowerCase() == _walletAddress?.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  // Superstar Avatar Registry Methods
  Future<String> registerSuperstarAvatar({
    required String avatarId,
    required String name,
    required String bio,
    required List<int> powerLevels,
    required List<int> powerExperience,
    required int totalExperience,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _superstarAvatarRegistryContract.function('registerSuperstarAvatar');
      final params = [
        avatarId,
        name,
        bio,
        powerLevels.map((e) => BigInt.from(e)).toList(),
        powerExperience.map((e) => BigInt.from(e)).toList(),
        BigInt.from(totalExperience),
      ];

      final transaction = Transaction.callContract(
        contract: _superstarAvatarRegistryContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to register Superstar Avatar: $e');
    }
  }

  Future<String> unlockAchievement({
    required String avatarId,
    required String achievementId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _superstarAvatarRegistryContract.function('unlockAchievement');
      final params = [avatarId, achievementId];

      final transaction = Transaction.callContract(
        contract: _superstarAvatarRegistryContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to unlock achievement: $e');
    }
  }

  Future<String> awardBadge({
    required String avatarId,
    required String badgeId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _superstarAvatarRegistryContract.function('awardBadge');
      final params = [avatarId, badgeId];

      final transaction = Transaction.callContract(
        contract: _superstarAvatarRegistryContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to award badge: $e');
    }
  }

  Future<Map<String, dynamic>?> getSuperstarAvatar(String avatarId) async {
    try {
      final function = _superstarAvatarRegistryContract.function('getSuperstarAvatar');
      final params = [avatarId];

      final result = await _client.call(
        contract: _superstarAvatarRegistryContract,
        function: function,
        params: params,
      );

      return {
        'id': result[0] as String,
        'name': result[1] as String,
        'bio': result[2] as String,
        'walletAddress': result[3] as String,
        'totalExperience': (result[4] as BigInt).toInt(),
        'powerLevels': (result[5] as List<BigInt>).map((e) => e.toInt()).toList(),
        'powerExperience': (result[6] as List<BigInt>).map((e) => e.toInt()).toList(),
        'achievedAt': (result[7] as BigInt).toInt(),
        'lastActive': (result[8] as BigInt).toInt(),
        'achievements': (result[9] as List<dynamic>).cast<String>(),
        'badges': (result[10] as List<dynamic>).cast<String>(),
        'isActive': result[11] as bool,
        'metadata': result[12] as String,
      };
    } catch (e) {
      return null;
    }
  }

  // Utility Methods
  Future<String> signMessage(String message) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final messageBytes = utf8.encode(message);
      final signature = await _credentials.signPersonalMessageToUint8List(messageBytes);
      return hex.encode(signature);
    } catch (e) {
      throw Exception('Failed to sign message: $e');
    }
  }

  bool verifySignature(String message, String signature, String address) {
    try {
      final messageBytes = utf8.encode(message);
      final signatureBytes = hex.decode(signature);
      
      return signatureBytes.length == 65; // ECDSA signature length
    } catch (e) {
      return false;
    }
  }

  String generateAvatarId(String walletAddress, String name) {
    final data = '$walletAddress:$name:${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16);
  }

  // Event Producer Methods
  Future<String> registerEventProducer({
    required String producerId,
    required String avatarId,
    required String name,
    required String description,
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Note: This would require adding EventProducer contract ABI
      // For now, this is a placeholder that shows the structure
      throw Exception('EventProducer contract integration pending');
    } catch (e) {
      throw Exception('Failed to register event producer: $e');
    }
  }

  Future<String> linkStripeAccountToProducer({
    required String producerId,
    required String stripeAccountId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Placeholder for Stripe account linking
      throw Exception('Stripe account linking pending');
    } catch (e) {
      throw Exception('Failed to link Stripe account: $e');
    }
  }

  // Event Listings Methods
  Future<String> createEvent({
    required String eventId,
    required String producerId,
    required String title,
    required String description,
    required String venue,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required int ticketPrice,
    required int maxTickets,
    required int category,
    String imageUri = "",
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Placeholder for event creation
      throw Exception('Event creation pending');
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Ticketing Methods
  Future<String> createTicket({
    required String ticketId,
    required String eventId,
    required String avatarId,
    required int price,
    required String stripePaymentIntentId,
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Placeholder for ticket creation
      throw Exception('Ticket creation pending');
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<String> validateTicket({
    required String ticketId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Placeholder for ticket validation
      throw Exception('Ticket validation pending');
    } catch (e) {
      throw Exception('Failed to validate ticket: $e');
    }
  }

  Future<String> checkInTicketWithQRCode({
    required String qrCodeHash,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      // Convert hex string to bytes32 for blockchain
      // Note: This would require adding Ticketing contract ABI
      // For now, this is a placeholder that shows the structure
      throw Exception('QR code check-in pending contract integration');
    } catch (e) {
      throw Exception('Failed to check in ticket: $e');
    }
  }

  Future<Map<String, dynamic>> getTicketFromQRCode(String qrCodeHash) async {
    try {
      // Get ticket information from QR code hash
      // Placeholder for ticket lookup
      throw Exception('Ticket lookup from QR code pending');
    } catch (e) {
      throw Exception('Failed to get ticket from QR code: $e');
    }
  }

  /// Check if error is an insufficient funds error
  bool _isInsufficientFundsError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('insufficient funds') ||
        errorString.contains('insufficientfunds') ||
        errorString.contains('insufficient balance');
  }

  // Avatar Registry Methods
  /// Create a new avatar profile on the blockchain (gasless via paymaster)
  Future<String> createAvatarProfile({
    required String avatarId,
    required String name,
    required String bio,
    required String imageUri,
    String houseId = "",
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Identity not connected');

    try {
      // Try to whitelist user for gasless avatar creation first
      // This will fail silently if sponsorship is not enabled, which is fine
      try {
        final adminService = AdminService();
        final isSponsored = await adminService.isAvatarCreationSponsored();
        
        if (isSponsored) {
          debugPrint('Avatar creation sponsorship enabled, whitelisting user...');
          try {
            await adminService.whitelistUserForAvatarCreation(_walletAddress!);
            debugPrint('User whitelisted for gasless avatar creation');
          } catch (e) {
            debugPrint('Could not whitelist user (may already be whitelisted): $e');
            // Continue anyway - user might already be whitelisted
          }
        }
      } catch (e) {
        debugPrint('Could not check/whitelist for avatar creation sponsorship: $e');
        // Continue with regular transaction if whitelisting fails
      }

      // Check balance - but allow transaction to proceed even with low balance
      // if user is whitelisted (will be sponsored by paymaster)
      final balance = await getBalance();
      final minRequired = BigInt.from(10000000000000000); // 0.01 MATIC minimum
      
      // Check if user is whitelisted
      bool isWhitelisted = false;
      try {
        final adminService = AdminService();
        final paymentInfo = await adminService.getUserPaymentInfo(_walletAddress!);
        isWhitelisted = paymentInfo['hasWhitelist'] as bool? ?? false;
      } catch (e) {
        debugPrint('Could not check whitelist status: $e');
      }

      // Only require balance if user is not whitelisted
      if (!isWhitelisted && balance < minRequired) {
        throw Exception(
          'Insufficient funds. You need at least 0.01 MATIC for gas fees. '
          'Please get testnet MATIC from the faucet.',
        );
      }

      final function = _avatarRegistryContract.function('createAvatar');
      final params = [avatarId, name, bio, imageUri, houseId, metadata];

      final transaction = Transaction.callContract(
        contract: _avatarRegistryContract,
        function: function,
        parameters: params,
      );

      // Note: If user is whitelisted and using account abstraction,
      // the paymaster will sponsor this transaction
      // For now, we use regular transactions - account abstraction integration
      // would require a bundler setup
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error creating avatar profile: $e');
      
      // Check if it's an insufficient funds error
      if (_isInsufficientFundsError(e)) {
        throw Exception(
          'Insufficient funds. You need MATIC to pay for gas fees. '
          'Please get testnet MATIC from the faucet.',
        );
      }
      
      throw Exception('Failed to create avatar profile: $e');
    }
  }

  /// Update avatar profile (name, bio, metadata)
  Future<String> updateAvatarProfile({
    required String avatarId,
    String name = "",
    String bio = "",
    String metadata = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _avatarRegistryContract.function('updateAvatar');
      final params = [avatarId, name, bio, metadata];

      final transaction = Transaction.callContract(
        contract: _avatarRegistryContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error updating avatar profile: $e');
      throw Exception('Failed to update avatar profile: $e');
    }
  }

  /// Update avatar image URI
  Future<String> updateAvatarImage({
    required String avatarId,
    required String newImageUri,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _avatarRegistryContract.function('updateAvatarImage');
      final params = [avatarId, newImageUri];

      final transaction = Transaction.callContract(
        contract: _avatarRegistryContract,
        function: function,
        parameters: params,
      );

      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error updating avatar image: $e');
      throw Exception('Failed to update avatar image: $e');
    }
  }

  /// Get avatar profile from blockchain
  Future<Map<String, dynamic>?> getAvatarProfile(String avatarId) async {
    try {
      final function = _avatarRegistryContract.function('getAvatar');
      final params = [avatarId];

      final result = await _client.call(
        contract: _avatarRegistryContract,
        function: function,
        params: params,
      );

      // Parse tuple result
      final tuple = result[0] as List<dynamic>;
      return {
        'id': tuple[0] as String,
        'name': tuple[1] as String,
        'bio': tuple[2] as String,
        'imageUri': tuple[3] as String,
        'walletAddress': (tuple[4] as EthereumAddress).hex,
        'createdAt': (tuple[5] as BigInt).toInt(),
        'updatedAt': (tuple[6] as BigInt).toInt(),
        'isActive': tuple[7] as bool,
        'isPrimary': tuple[8] as bool,
        'houseId': tuple[9] as String,
        'metadata': tuple[10] as String,
      };
    } catch (e) {
      debugPrint('Error getting avatar profile: $e');
      return null;
    }
  }

  /// Get all avatar IDs by wallet address
  Future<List<String>> getAvatarIdsByAddress(String walletAddress) async {
    try {
      final function = _avatarRegistryContract.function('getAvatarIdsByAddress');
      final params = [EthereumAddress.fromHex(walletAddress)];

      final result = await _client.call(
        contract: _avatarRegistryContract,
        function: function,
        params: params,
      );

      return (result[0] as List<dynamic>).map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting avatar IDs by address: $e');
      return [];
    }
  }

  /// Get primary avatar ID by wallet address
  Future<String?> getPrimaryAvatarIdByAddress(String walletAddress) async {
    try {
      final function = _avatarRegistryContract.function('getPrimaryAvatarIdByAddress');
      final params = [EthereumAddress.fromHex(walletAddress)];

      final result = await _client.call(
        contract: _avatarRegistryContract,
        function: function,
        params: params,
      );

      final avatarId = result[0] as String;
      return avatarId.isEmpty ? null : avatarId;
    } catch (e) {
      debugPrint('Error getting primary avatar ID by address: $e');
      return null;
    }
  }

  /// Get avatar count by wallet address
  Future<int> getAvatarCountByAddress(String walletAddress) async {
    try {
      final function = _avatarRegistryContract.function('getAvatarCountByAddress');
      final params = [EthereumAddress.fromHex(walletAddress)];

      final result = await _client.call(
        contract: _avatarRegistryContract,
        function: function,
        params: params,
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      debugPrint('Error getting avatar count by address: $e');
      return 0;
    }
  }

  /// Check if avatar exists on blockchain
  Future<bool> avatarExistsOnBlockchain(String avatarId) async {
    try {
      final function = _avatarRegistryContract.function('avatarExistsCheck');
      final params = [avatarId];

      final result = await _client.call(
        contract: _avatarRegistryContract,
        function: function,
        params: params,
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking avatar existence: $e');
      return false;
    }
  }

  void dispose() {
    _client.dispose();
    _isInitialized = false;
  }
} 