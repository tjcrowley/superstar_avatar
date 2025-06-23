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

  // Smart Contract ABIs (simplified for demo)
  static const String powerVerificationABI = '''
    [
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "powerType", "type": "uint8"},
          {"name": "experience", "type": "uint256"},
          {"name": "verifierId", "type": "string"}
        ],
        "name": "verifyPower",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getPowerLevel",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String houseMembershipABI = '''
    [
      {
        "inputs": [
          {"name": "avatarId", "type": "string"},
          {"name": "houseId", "type": "string"}
        ],
        "name": "joinHouse",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "avatarId", "type": "string"}],
        "name": "getHouseId",
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  static const String activityScriptABI = '''
    [
      {
        "inputs": [
          {"name": "activityId", "type": "string"},
          {"name": "title", "type": "string"},
          {"name": "authorId", "type": "string"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "createActivity",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "activityId", "type": "string"}],
        "name": "getActivity",
        "outputs": [
          {"name": "title", "type": "string"},
          {"name": "authorId", "type": "string"},
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

  Future<String> verifyPower({
    required String avatarId,
    required int powerType,
    required int experience,
    required String verifierId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(powerVerificationABI, 'PowerVerification'),
        EthereumAddress.fromHex(AppConstants.powerVerificationContractAddress),
      );

      final function = contract.function('verifyPower');
      final params = [
        avatarId,
        BigInt.from(powerType),
        BigInt.from(experience),
        verifierId,
      ];

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: contract,
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

  Future<int> getPowerLevel(String avatarId, int powerType) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(powerVerificationABI, 'PowerVerification'),
        EthereumAddress.fromHex(AppConstants.powerVerificationContractAddress),
      );

      final function = contract.function('getPowerLevel');
      final params = [avatarId, BigInt.from(powerType)];

      final result = await _client.call(
        contract: contract,
        function: function,
        params: params,
      );

      return (result.first as BigInt).toInt();
    } catch (e) {
      throw Exception('Failed to get power level: $e');
    }
  }

  Future<String> joinHouse({
    required String avatarId,
    required String houseId,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(houseMembershipABI, 'HouseMembership'),
        EthereumAddress.fromHex(AppConstants.houseMembershipContractAddress),
      );

      final function = contract.function('joinHouse');
      final params = [avatarId, houseId];

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: contract,
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

  Future<String?> getHouseId(String avatarId) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(houseMembershipABI, 'HouseMembership'),
        EthereumAddress.fromHex(AppConstants.houseMembershipContractAddress),
      );

      final function = contract.function('getHouseId');
      final params = [avatarId];

      final result = await _client.call(
        contract: contract,
        function: function,
        params: params,
      );

      return result.first as String;
    } catch (e) {
      return null;
    }
  }

  Future<String> createActivity({
    required String activityId,
    required String title,
    required String authorId,
    required Map<String, dynamic> metadata,
  }) async {
    if (!isWalletConnected) throw Exception('Wallet not connected');

    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(activityScriptABI, 'ActivityScript'),
        EthereumAddress.fromHex(AppConstants.activityScriptContractAddress),
      );

      final function = contract.function('createActivity');
      final params = [
        activityId,
        title,
        authorId,
        jsonEncode(metadata),
      ];

      final transaction = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: contract,
          function: function,
          params: params,
        ),
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return transaction;
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  Future<Map<String, dynamic>?> getActivity(String activityId) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(activityScriptABI, 'ActivityScript'),
        EthereumAddress.fromHex(AppConstants.activityScriptContractAddress),
      );

      final function = contract.function('getActivity');
      final params = [activityId];

      final result = await _client.call(
        contract: contract,
        function: function,
        params: params,
      );

      return {
        'title': result[0] as String,
        'authorId': result[1] as String,
        'metadata': jsonDecode(result[2] as String),
      };
    } catch (e) {
      return null;
    }
  }

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
      // Simplified signature verification - in production, use proper ECDSA recovery
      final messageBytes = utf8.encode(message);
      final signatureBytes = hex.decode(signature);
      
      // This is a simplified check - in a real implementation, you would use
      // proper ECDSA signature recovery to get the address from the signature
      final messageHash = sha256.convert(messageBytes);
      final signatureHash = sha256.convert(signatureBytes);
      
      // For demo purposes, we'll just check if the signature is valid format
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