import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'blockchain_service.dart';
import 'transaction_service.dart';

/// Service for interacting with the Goldfire (GF) token contract
class GoldfireTokenService {
  final BlockchainService _blockchainService = BlockchainService();
  final TransactionService _transactionService = TransactionService();
  
  static const String goldfireTokenABI = '''
    [
      {
        "inputs": [{"name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "totalSupply",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "name",
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "symbol",
        "outputs": [{"name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "decimals",
        "outputs": [{"name": "", "type": "uint8"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "spender", "type": "address"},
          {"name": "amount", "type": "uint256"}
        ],
        "name": "approve",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "owner", "type": "address"},
          {"name": "spender", "type": "address"}
        ],
        "name": "allowance",
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [
          {"name": "to", "type": "address"},
          {"name": "amount", "type": "uint256"}
        ],
        "name": "transfer",
        "outputs": [{"name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [{"name": "amount", "type": "uint256"}],
        "name": "burn",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]
  ''';

  DeployedContract? _goldfireTokenContract;

  Web3Client get client => _blockchainService.client;
  Credentials get credentials => _blockchainService.credentials;

  Future<void> _initializeContract() async {
    if (_goldfireTokenContract != null) return;
    
    await _blockchainService.initialize();
    
    _goldfireTokenContract = DeployedContract(
      ContractAbi.fromJson(goldfireTokenABI, 'GoldfireToken'),
      EthereumAddress.fromHex(AppConstants.goldfireTokenContractAddress),
    );
  }

  /// Get Goldfire token balance for an address
  Future<BigInt> getBalance(String address) async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('balanceOf');
      final params = [EthereumAddress.fromHex(address)];

      final result = await client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: params,
      );

      return result[0] as BigInt;
    } catch (e) {
      debugPrint('Error getting Goldfire balance: $e');
      return BigInt.zero;
    }
  }

  /// Get Goldfire token balance for current wallet
  Future<BigInt> getMyBalance() async {
    if (!_blockchainService.isWalletConnected) {
      throw Exception('Identity not connected');
    }
    
    return getBalance(_blockchainService.walletAddress!);
  }

  /// Get total supply of Goldfire tokens
  Future<BigInt> getTotalSupply() async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('totalSupply');
      final result = await _blockchainService.client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: [],
      );

      return result[0] as BigInt;
    } catch (e) {
      debugPrint('Error getting total supply: $e');
      return BigInt.zero;
    }
  }

  /// Get token name
  Future<String> getName() async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('name');
      final result = await _blockchainService.client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: [],
      );

      return result[0] as String;
    } catch (e) {
      return 'Goldfire';
    }
  }

  /// Get token symbol
  Future<String> getSymbol() async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('symbol');
      final result = await _blockchainService.client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: [],
      );

      return result[0] as String;
    } catch (e) {
      return 'GF';
    }
  }

  /// Get token decimals
  Future<int> getDecimals() async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('decimals');
      final result = await _blockchainService.client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: [],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      return 18; // Default to 18 decimals
    }
  }

  /// Transfer Goldfire tokens
  Future<String> transfer(String to, BigInt amount) async {
    if (!_blockchainService.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContract();

    try {
      final function = _goldfireTokenContract!.function('transfer');
      final params = [EthereumAddress.fromHex(to), amount];

      final txHash = await _transactionService.sendTransaction(
        contract: _goldfireTokenContract!,
        function: function,
        parameters: params,
      );

      return txHash;
    } catch (e) {
      debugPrint('Error transferring Goldfire tokens: $e');
      throw Exception('Failed to transfer Goldfire tokens: $e');
    }
  }

  /// Approve Goldfire tokens for a spender (e.g., Paymaster)
  Future<String> approve(String spender, BigInt amount) async {
    if (!_blockchainService.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContract();

    try {
      final function = _goldfireTokenContract!.function('approve');
      final params = [EthereumAddress.fromHex(spender), amount];

      final txHash = await _transactionService.sendTransaction(
        contract: _goldfireTokenContract!,
        function: function,
        parameters: params,
      );

      return txHash;
    } catch (e) {
      debugPrint('Error approving Goldfire tokens: $e');
      throw Exception('Failed to approve Goldfire tokens: $e');
    }
  }

  /// Get allowance for a spender
  Future<BigInt> getAllowance(String owner, String spender) async {
    await _initializeContract();
    
    try {
      final function = _goldfireTokenContract!.function('allowance');
      final params = [
        EthereumAddress.fromHex(owner),
        EthereumAddress.fromHex(spender),
      ];

      final result = await client.call(
        contract: _goldfireTokenContract!,
        function: function,
        params: params,
      );

      return result[0] as BigInt;
    } catch (e) {
      debugPrint('Error getting allowance: $e');
      return BigInt.zero;
    }
  }

  /// Mint Goldfire tokens (admin only)
  Future<String> mint(String to, BigInt amount) async {
    if (!_blockchainService.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContract();

    try {
      final function = _goldfireTokenContract!.function('mint');
      final params = [EthereumAddress.fromHex(to), amount];

      final transaction = Transaction.callContract(
        contract: _goldfireTokenContract!,
        function: function,
        parameters: params,
      );

      final txHash = await _blockchainService.client.sendTransaction(
        _blockchainService.credentials,
        transaction,
        chainId: int.parse(AppConstants.polygonChainId),
      );

      return txHash;
    } catch (e) {
      debugPrint('Error minting Goldfire tokens: $e');
      throw Exception('Failed to mint Goldfire tokens: $e');
    }
  }

  /// Burn Goldfire tokens (user-initiated)
  Future<String> burn(BigInt amount) async {
    if (!_blockchainService.isWalletConnected) {
      throw Exception('Identity not connected');
    }

    await _initializeContract();

    try {
      final function = _goldfireTokenContract!.function('burn');
      final params = [amount];

      final txHash = await _transactionService.sendTransaction(
        contract: _goldfireTokenContract!,
        function: function,
        parameters: params,
      );

      return txHash;
    } catch (e) {
      debugPrint('Error burning Goldfire tokens: $e');
      throw Exception('Failed to burn Goldfire tokens: $e');
    }
  }

  /// Convert wei amount to human-readable format
  Future<String> formatAmount(BigInt amount) async {
    final decimals = await getDecimals();
    final divisor = BigInt.from(10).pow(decimals);
    final whole = amount ~/ divisor;
    final fraction = amount % divisor;
    
    if (fraction == BigInt.zero) {
      return whole.toString();
    }
    
    final fractionStr = fraction.toString().padLeft(decimals, '0');
    final trimmed = fractionStr.replaceAll(RegExp(r'0+$'), '');
    
    if (trimmed.isEmpty) {
      return whole.toString();
    }
    
    return '$whole.$trimmed';
  }

  /// Parse human-readable amount to wei
  Future<BigInt> parseAmount(String amount) async {
    final decimals = await getDecimals();
    final parts = amount.split('.');
    final whole = BigInt.parse(parts[0]);
    
    if (parts.length == 1) {
      return whole * BigInt.from(10).pow(decimals);
    }
    
    final fraction = parts[1].padRight(decimals, '0').substring(0, decimals);
    final fractionBigInt = BigInt.parse(fraction);
    
    return whole * BigInt.from(10).pow(decimals) + fractionBigInt;
  }
}

