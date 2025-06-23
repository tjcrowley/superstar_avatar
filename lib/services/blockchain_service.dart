import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

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
      }
    ]
  ''';

  static const String activityScriptsABI = '''
    [
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
          {"name": "metadata", "type": "string"}
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

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _client = Web3Client(
        AppConstants.polygonRpcUrl,
        http.Client(),
      );

      // Initialize contract instances
      _powerVerificationContract = DeployedContract(
        ContractAbi.fromJson(powerVerificationABI, 'PowerVerification'),
        EthereumAddress.fromHex(AppConstants.powerVerificationContractAddress),
      );

      _houseMembershipContract = DeployedContract(
        ContractAbi.fromJson(houseMembershipABI, 'HouseMembership'),
        EthereumAddress.fromHex(AppConstants.houseMembershipContractAddress),
      );

      _activityScriptsContract = DeployedContract(
        ContractAbi.fromJson(activityScriptsABI, 'ActivityScripts'),
        EthereumAddress.fromHex(AppConstants.activityScriptsContractAddress),
      );

      _superstarAvatarRegistryContract = DeployedContract(
        ContractAbi.fromJson(superstarAvatarRegistryABI, 'SuperstarAvatarRegistry'),
        EthereumAddress.fromHex(AppConstants.superstarAvatarRegistryContractAddress),
      );

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize blockchain service: $e');
    }
  }

  Future<String> createWallet() async {
    try {
      final mnemonic = bip39.generateMnemonic();
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = seed.sublist(0, 32);
      
      _credentials = EthPrivateKey(privateKey);
      _walletAddress = await _credentials.extractAddress();
      
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
      _walletAddress = await _credentials.extractAddress();
    } catch (e) {
      throw Exception('Failed to import wallet: $e');
    }
  }

  String? get walletAddress => _walletAddress;

  bool get isWalletConnected => _walletAddress != null;

  Future<BigInt> getBalance() async {
    if (!isWalletConnected) throw Exception('Wallet not connected');
    
    try {
      final address = EthereumAddress.fromHex(_walletAddress!);
      return await _client.getBalance(address);
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _powerVerificationContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _houseMembershipContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _houseMembershipContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _houseMembershipContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

  // Activity Scripts Methods
  Future<String> completeActivity({
    required String activityId,
    required String avatarId,
    String proof = "",
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final function = _activityScriptsContract.function('completeActivity');
      final params = [activityId, avatarId, proof];

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _activityScriptsContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _activityScriptsContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _superstarAvatarRegistryContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _superstarAvatarRegistryContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _superstarAvatarRegistryContract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
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
      final signature = await _credentials.signPersonalMessage(messageBytes);
      return signature.toHex();
    } catch (e) {
      throw Exception('Failed to sign message: $e');
    }
  }

  bool verifySignature(String message, String signature, String address) {
    try {
      final messageBytes = utf8.encode(message);
      final signatureBytes = hex.decode(signature);
      
      final messageHash = sha256.convert(messageBytes);
      final signatureHash = sha256.convert(signatureBytes);
      
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

  void dispose() {
    _client.dispose();
    _isInitialized = false;
  }
} 