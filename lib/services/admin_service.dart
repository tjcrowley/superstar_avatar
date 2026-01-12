import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'blockchain_service.dart';
import 'goldfire_token_service.dart';
import 'transaction_service.dart';

/// Service for admin operations and admin registry interactions
class AdminService {
  // Lazy-initialize services to avoid circular dependencies
  BlockchainService? _blockchainService;
  BlockchainService get _blockchainServiceInstance {
    return _blockchainService ??= BlockchainService();
  }
  
  TransactionService? _transactionService;
  TransactionService get _transactionServiceInstance {
    return _transactionService ??= TransactionService();
  }
  
  static const String adminRegistryABI = '''
    [
      {
        "inputs": [{"name": "account", "type": "address"}],
        "name": "checkAdmin",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "getAdminCount",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "getAllAdmins",
        "outputs": [{"name": "", "type": "address[]"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "admin", "type": "address"}],
        "name": "addAdmin",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "admin", "type": "address"}],
        "name": "removeAdmin",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
  ''';

  static const String paymasterABI = '''
    [
      {
        "inputs": [],
        "name": "getBalance",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "amount", "type": "uint256"}],
        "name": "withdraw",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      },
      {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "addToWhitelist",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "removeFromWhitelist",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "getUserPaymentInfo",
        "outputs": [
          {"name": "hasWhitelist", "type": "bool"},
          {"name": "nativeDeposit", "type": "uint256"},
          {"name": "goldfireBalance", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "whitelistForAvatarCreation",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "sponsorAvatarCreation",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "sponsorAllTransactions",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "enabled", "type": "bool"}],
        "name": "setSponsorAllTransactions",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "user", "type": "address"}],
        "name": "whitelistForAllTransactions",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
  ''';

  static const String eventProducerABI = '''
    [
      {
        "inputs": [
          {"name": "producerId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "walletAddress", "type": "address"},
          {"name": "metadata", "type": "string"}
        ],
        "name": "adminRegisterProducer",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "producerId", "type": "string"}],
        "name": "getProducer",
        "outputs": [
          {"name": "producerId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "stripeAccountId", "type": "string"},
          {"name": "walletAddress", "type": "address"},
          {"name": "createdAt", "type": "uint256"},
          {"name": "lastActive", "type": "uint256"},
          {"name": "totalEvents", "type": "uint256"},
          {"name": "totalTicketsSold", "type": "uint256"},
          {"name": "totalRevenue", "type": "uint256"},
          {"name": "isVerified", "type": "bool"},
          {"name": "isActive", "type": "bool"},
          {"name": "metadata", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [{"name": "walletAddress", "type": "address"}],
        "name": "getProducerByAddress",
        "outputs": [
          {"name": "producerId", "type": "string"},
          {"name": "avatarId", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "stripeAccountId", "type": "string"},
          {"name": "walletAddress", "type": "address"},
          {"name": "createdAt", "type": "uint256"},
          {"name": "lastActive", "type": "uint256"},
          {"name": "totalEvents", "type": "uint256"},
          {"name": "totalTicketsSold", "type": "uint256"},
          {"name": "totalRevenue", "type": "uint256"},
          {"name": "isVerified", "type": "bool"},
          {"name": "isActive", "type": "bool"},
          {"name": "metadata", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ]
  ''';

  DeployedContract? _adminRegistryContract;
  DeployedContract? _paymasterContract;
  DeployedContract? _eventProducerContract;

  Future<void> _initializeContracts() async {
    if (_adminRegistryContract != null && _paymasterContract != null && _eventProducerContract != null) return;
    
    await _blockchainServiceInstance.initialize();
    
    _adminRegistryContract = DeployedContract(
      ContractAbi.fromJson(adminRegistryABI, 'AdminRegistry'),
      EthereumAddress.fromHex(AppConstants.adminRegistryContractAddress),
    );
    
    _paymasterContract = DeployedContract(
      ContractAbi.fromJson(paymasterABI, 'GoldfirePaymaster'),
      EthereumAddress.fromHex(AppConstants.paymasterContractAddress),
    );
    
    if (AppConstants.eventProducerContractAddress != '0x0000000000000000000000000000000000000000') {
      _eventProducerContract = DeployedContract(
        ContractAbi.fromJson(eventProducerABI, 'EventProducer'),
        EthereumAddress.fromHex(AppConstants.eventProducerContractAddress),
      );
    }
  }

  /// Check if current wallet is an admin
  Future<bool> isAdmin() async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      return false;
    }

    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('checkAdmin');
      final params = [EthereumAddress.fromHex(_blockchainServiceInstance.walletAddress!)];

      final result = await _blockchainServiceInstance.client.call(
        contract: _adminRegistryContract!,
        function: function,
        params: params,
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if an address is an admin
  Future<bool> isAdminAddress(String address) async {
    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('checkAdmin');
      final params = [EthereumAddress.fromHex(address)];

      final result = await _blockchainServiceInstance.client.call(
        contract: _adminRegistryContract!,
        function: function,
        params: params,
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all admin addresses
  Future<List<String>> getAllAdmins() async {
    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('getAllAdmins');
      final result = await _blockchainServiceInstance.client.call(
        contract: _adminRegistryContract!,
        function: function,
        params: [],
      );

      final addresses = result[0] as List<dynamic>;
      return addresses.map((addr) => (addr as EthereumAddress).hex).toList();
    } catch (e) {
      debugPrint('Error getting all admins: $e');
      return [];
    }
  }

  /// Get admin count
  Future<int> getAdminCount() async {
    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('getAdminCount');
      final result = await _blockchainServiceInstance.client.call(
        contract: _adminRegistryContract!,
        function: function,
        params: [],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      debugPrint('Error getting admin count: $e');
      return 0;
    }
  }

  /// Add an admin (owner only)
  Future<String> addAdmin(String adminAddress) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('addAdmin');
      final params = [EthereumAddress.fromHex(adminAddress)];

      final transaction = Transaction.callContract(
        contract: _adminRegistryContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error adding admin: $e');
      throw Exception('Failed to add admin: $e');
    }
  }

  /// Remove an admin (owner only)
  Future<String> removeAdmin(String adminAddress) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _adminRegistryContract!.function('removeAdmin');
      final params = [EthereumAddress.fromHex(adminAddress)];

      final transaction = Transaction.callContract(
        contract: _adminRegistryContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error removing admin: $e');
      throw Exception('Failed to remove admin: $e');
    }
  }

  /// Mint Goldfire tokens to a user (admin only)
  Future<String> mintGoldfireTokens(String to, BigInt amount) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    // Check if caller is admin
    final isAdminUser = await isAdmin();
    if (!isAdminUser) {
      throw Exception('Only admins can mint tokens');
    }

    // Use GoldfireTokenService mint function
    final goldfireService = GoldfireTokenService();
    return await goldfireService.mint(to, amount);
  }

  /// Get paymaster balance
  Future<BigInt> getPaymasterBalance() async {
    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('getBalance');
      final result = await _blockchainServiceInstance.client.call(
        contract: _paymasterContract!,
        function: function,
        params: [],
      );

      return result[0] as BigInt;
    } catch (e) {
      debugPrint('Error getting paymaster balance: $e');
      return BigInt.zero;
    }
  }

  /// Deposit native tokens to paymaster (admin only)
  /// Note: This uses a regular transaction (not via TransactionService) because:
  /// 1. Admin needs to send native tokens as value
  /// 2. Admin should pay gas for this operation (depositing funds to paymaster)
  Future<String> depositToPaymaster(BigInt amount) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      debugPrint('Depositing ${amount} wei (${EtherAmount.fromBigInt(EtherUnit.wei, amount).getValueInUnit(EtherUnit.ether)} MATIC) to paymaster');
      
      final function = _paymasterContract!.function('deposit');
      
      // Create transaction with native token value
      final transaction = Transaction.callContract(
        contract: _paymasterContract!,
        function: function,
        parameters: [],
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      );

      // Send transaction directly (admin needs to pay gas for deposit)
      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      debugPrint('Deposit transaction submitted: $txHash');
      return txHash;
    } catch (e) {
      debugPrint('Error depositing to paymaster: $e');
      debugPrint('Error type: ${e.runtimeType}');
      throw Exception('Failed to deposit to paymaster: $e');
    }
  }

  /// Withdraw native tokens from paymaster (admin only)
  Future<String> withdrawFromPaymaster(BigInt amount) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('withdraw');
      final params = [amount];

      final transaction = Transaction.callContract(
        contract: _paymasterContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error withdrawing from paymaster: $e');
      throw Exception('Failed to withdraw from paymaster: $e');
    }
  }

  /// Add user to paymaster whitelist (admin only)
  Future<String> addUserToWhitelist(String userAddress) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('addToWhitelist');
      final params = [EthereumAddress.fromHex(userAddress)];

      final transaction = Transaction.callContract(
        contract: _paymasterContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error adding user to whitelist: $e');
      throw Exception('Failed to add user to whitelist: $e');
    }
  }

  /// Get user payment info from paymaster
  Future<Map<String, dynamic>> getUserPaymentInfo(String userAddress) async {
    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('getUserPaymentInfo');
      final params = [EthereumAddress.fromHex(userAddress)];

      final result = await _blockchainServiceInstance.client.call(
        contract: _paymasterContract!,
        function: function,
        params: params,
      );

      return {
        'hasWhitelist': result[0] as bool,
        'nativeDeposit': result[1] as BigInt,
        'goldfireBalance': result[2] as BigInt,
      };
    } catch (e) {
      debugPrint('Error getting user payment info: $e');
      return {
        'hasWhitelist': false,
        'nativeDeposit': BigInt.zero,
        'goldfireBalance': BigInt.zero,
      };
    }
  }

  /// Whitelist user for avatar creation (can be called by anyone if sponsorship is enabled)
  Future<String> whitelistUserForAvatarCreation(String userAddress) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('whitelistForAvatarCreation');
      final params = [EthereumAddress.fromHex(userAddress)];

      final txHash = await _transactionServiceInstance.sendTransaction(
        contract: _paymasterContract!,
        function: function,
        parameters: params,
      );

      return txHash;
    } catch (e) {
      debugPrint('Error whitelisting user for avatar creation: $e');
      throw Exception('Failed to whitelist user: $e');
    }
  }

  /// Check if avatar creation sponsorship is enabled
  Future<bool> isAvatarCreationSponsored() async {
    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('sponsorAvatarCreation');
      final result = await _blockchainServiceInstance.client.call(
        contract: _paymasterContract!,
        function: function,
        params: [],
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking avatar creation sponsorship: $e');
      return false;
    }
  }

  /// Check if all transactions sponsorship is enabled
  Future<bool> isAllTransactionsSponsored() async {
    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('sponsorAllTransactions');
      final result = await _blockchainServiceInstance.client.call(
        contract: _paymasterContract!,
        function: function,
        params: [],
      );

      return result[0] as bool;
    } catch (e) {
      debugPrint('Error checking all transactions sponsorship: $e');
      return false;
    }
  }

  /// Enable/disable sponsorship of all transactions (admin only)
  Future<String> setSponsorAllTransactions(bool enabled) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('setSponsorAllTransactions');
      final params = [enabled];

      final transaction = Transaction.callContract(
        contract: _paymasterContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error setting all transactions sponsorship: $e');
      throw Exception('Failed to set all transactions sponsorship: $e');
    }
  }

  /// Whitelist user for all gasless transactions (can be called by anyone if sponsorship is enabled)
  Future<String> whitelistUserForAllTransactions(String userAddress) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContracts();

    try {
      final function = _paymasterContract!.function('whitelistForAllTransactions');
      final params = [EthereumAddress.fromHex(userAddress)];

      final txHash = await _transactionServiceInstance.sendTransaction(
        contract: _paymasterContract!,
        function: function,
        parameters: params,
      );

      return txHash;
    } catch (e) {
      debugPrint('Error whitelisting user for all transactions: $e');
      throw Exception('Failed to whitelist user: $e');
    }
  }

  /// Register an event producer (admin only)
  Future<String> registerEventProducer({
    required String producerId,
    required String avatarId,
    required String name,
    required String description,
    required String walletAddress,
    String metadata = '',
  }) async {
    if (!_blockchainServiceInstance.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    // Check if caller is admin
    final isAdminUser = await isAdmin();
    if (!isAdminUser) {
      throw Exception('Only admins can register event producers');
    }

    await _initializeContracts();

    if (_eventProducerContract == null) {
      throw Exception('EventProducer contract not configured');
    }

    try {
      final function = _eventProducerContract!.function('adminRegisterProducer');
      final params = [
        producerId,
        avatarId,
        name,
        description,
        EthereumAddress.fromHex(walletAddress),
        metadata,
      ];

      final transaction = Transaction.callContract(
        contract: _eventProducerContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainServiceInstance.client.sendTransaction(
        _blockchainServiceInstance.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error registering event producer: $e');
      throw Exception('Failed to register event producer: $e');
    }
  }

  /// Get event producer by address
  Future<Map<String, dynamic>?> getEventProducerByAddress(String walletAddress) async {
    await _initializeContracts();

    if (_eventProducerContract == null) {
      return null;
    }

    try {
      final function = _eventProducerContract!.function('getProducerByAddress');
      final params = [EthereumAddress.fromHex(walletAddress)];

      final result = await _blockchainServiceInstance.client.call(
        contract: _eventProducerContract!,
        function: function,
        params: params,
      );

      return {
        'producerId': result[0] as String,
        'avatarId': result[1] as String,
        'name': result[2] as String,
        'description': result[3] as String,
        'stripeAccountId': result[4] as String,
        'walletAddress': (result[5] as EthereumAddress).hex,
        'createdAt': (result[6] as BigInt).toInt(),
        'lastActive': (result[7] as BigInt).toInt(),
        'totalEvents': (result[8] as BigInt).toInt(),
        'totalTicketsSold': (result[9] as BigInt).toInt(),
        'totalRevenue': (result[10] as BigInt).toInt(),
        'isVerified': result[11] as bool,
        'isActive': result[12] as bool,
        'metadata': result[13] as String,
      };
    } catch (e) {
      debugPrint('Error getting event producer: $e');
      return null;
    }
  }
}

