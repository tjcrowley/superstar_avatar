import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/blockchain_service.dart';
import '../services/stripe_service.dart';
import '../constants/app_constants.dart';

class EventProducer {
  final String producerId;
  final String avatarId;
  final String name;
  final String description;
  final String? stripeAccountId;
  final String walletAddress;
  final DateTime createdAt;
  final DateTime lastActive;
  final int totalEvents;
  final int totalTicketsSold;
  final int totalRevenue;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  EventProducer({
    required this.producerId,
    required this.avatarId,
    required this.name,
    required this.description,
    this.stripeAccountId,
    required this.walletAddress,
    required this.createdAt,
    required this.lastActive,
    required this.totalEvents,
    required this.totalTicketsSold,
    required this.totalRevenue,
    required this.isVerified,
    required this.isActive,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'producerId': producerId,
      'avatarId': avatarId,
      'name': name,
      'description': description,
      'stripeAccountId': stripeAccountId,
      'walletAddress': walletAddress,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'totalEvents': totalEvents,
      'totalTicketsSold': totalTicketsSold,
      'totalRevenue': totalRevenue,
      'isVerified': isVerified,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory EventProducer.fromJson(Map<String, dynamic> json) {
    return EventProducer(
      producerId: json['producerId'] as String,
      avatarId: json['avatarId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      stripeAccountId: json['stripeAccountId'] as String?,
      walletAddress: json['walletAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      totalEvents: json['totalEvents'] as int,
      totalTicketsSold: json['totalTicketsSold'] as int,
      totalRevenue: json['totalRevenue'] as int,
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class EventProducerNotifier extends StateNotifier<EventProducer?> {
  final BlockchainService _blockchainService = BlockchainService();
  final StripeService _stripeService = StripeService();
  final SharedPreferences _prefs;

  EventProducerNotifier(this._prefs) : super(null) {
    _loadProducer();
  }

  Future<void> _loadProducer() async {
    try {
      final producerJson = _prefs.getString('event_producer_data');
      if (producerJson != null) {
        final producerData = jsonDecode(producerJson);
        state = EventProducer.fromJson(producerData);
      }
    } catch (e) {
      print('Error loading event producer: $e');
    }
  }

  Future<void> _saveProducer(EventProducer producer) async {
    try {
      final producerJson = jsonEncode(producer.toJson());
      await _prefs.setString('event_producer_data', producerJson);
      state = producer;
    } catch (e) {
      print('Error saving event producer: $e');
    }
  }

  Future<void> registerAsProducer({
    required String avatarId,
    required String name,
    required String description,
    String? email,
    String? country,
  }) async {
    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      final walletAddress = _blockchainService.walletAddress!;
      final producerId = _blockchainService.generateAvatarId(walletAddress, name);

      // Register on blockchain
      await _blockchainService.registerEventProducer(
        producerId: producerId,
        avatarId: avatarId,
        name: name,
        description: description,
      );

      // Create Stripe Connect account if email and country provided
      String? stripeAccountId;
      if (email != null && country != null) {
        try {
          final account = await _stripeService.createConnectAccount(
            email: email,
            country: country,
          );
          stripeAccountId = account['id'] as String;

          // Link Stripe account to producer
          await _blockchainService.linkStripeAccountToProducer(
            producerId: producerId,
            stripeAccountId: stripeAccountId,
          );
        } catch (e) {
          print('Error creating Stripe account: $e');
          // Continue without Stripe account - can be linked later
        }
      }

      final producer = EventProducer(
        producerId: producerId,
        avatarId: avatarId,
        name: name,
        description: description,
        stripeAccountId: stripeAccountId,
        walletAddress: walletAddress,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        totalEvents: 0,
        totalTicketsSold: 0,
        totalRevenue: 0,
        isVerified: false,
        isActive: true,
      );

      await _saveProducer(producer);
    } catch (e) {
      throw Exception('Failed to register as event producer: $e');
    }
  }

  Future<String> linkStripeAccount({
    required String email,
    required String country,
    required String returnUrl,
    required String refreshUrl,
  }) async {
    if (state == null) throw Exception('No producer found');

    try {
      // Create or get Stripe Connect account
      String stripeAccountId;
      if (state!.stripeAccountId != null) {
        stripeAccountId = state!.stripeAccountId!;
      } else {
        final account = await _stripeService.createConnectAccount(
          email: email,
          country: country,
        );
        stripeAccountId = account['id'] as String;
      }

      // Create account link for onboarding
      final accountLink = await _stripeService.createAccountLink(
        accountId: stripeAccountId,
        returnUrl: returnUrl,
        refreshUrl: refreshUrl,
      );

      // Link account on blockchain
      await _blockchainService.linkStripeAccountToProducer(
        producerId: state!.producerId,
        stripeAccountId: stripeAccountId,
      );

      // Update local state
      final updatedProducer = EventProducer(
        producerId: state!.producerId,
        avatarId: state!.avatarId,
        name: state!.name,
        description: state!.description,
        stripeAccountId: stripeAccountId,
        walletAddress: state!.walletAddress,
        createdAt: state!.createdAt,
        lastActive: DateTime.now(),
        totalEvents: state!.totalEvents,
        totalTicketsSold: state!.totalTicketsSold,
        totalRevenue: state!.totalRevenue,
        isVerified: state!.isVerified,
        isActive: state!.isActive,
      );

      await _saveProducer(updatedProducer);

      // Return onboarding URL
      return accountLink['url'] as String;
    } catch (e) {
      throw Exception('Failed to link Stripe account: $e');
    }
  }

  Future<void> updateProducer({
    String? name,
    String? description,
  }) async {
    if (state == null) throw Exception('No producer found');

    try {
      final updatedProducer = EventProducer(
        producerId: state!.producerId,
        avatarId: state!.avatarId,
        name: name ?? state!.name,
        description: description ?? state!.description,
        stripeAccountId: state!.stripeAccountId,
        walletAddress: state!.walletAddress,
        createdAt: state!.createdAt,
        lastActive: DateTime.now(),
        totalEvents: state!.totalEvents,
        totalTicketsSold: state!.totalTicketsSold,
        totalRevenue: state!.totalRevenue,
        isVerified: state!.isVerified,
        isActive: state!.isActive,
      );

      await _saveProducer(updatedProducer);
    } catch (e) {
      throw Exception('Failed to update producer: $e');
    }
  }

  bool get isProducer => state != null;
  bool get isVerified => state?.isVerified ?? false;
  bool get hasStripeAccount => state?.stripeAccountId != null;
  String? get stripeAccountId => state?.stripeAccountId;
}

// SharedPreferences provider (reuse from avatar_provider)
final eventProducerProvider = StateNotifierProvider<EventProducerNotifier, EventProducer?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    return EventProducerNotifier(SharedPreferences.getInstance() as SharedPreferences);
  }
  return EventProducerNotifier(prefs);
});

// Derived providers
final isEventProducerProvider = Provider<bool>((ref) {
  return ref.watch(eventProducerProvider) != null;
});

final eventProducerStripeAccountProvider = Provider<String?>((ref) {
  return ref.watch(eventProducerProvider)?.stripeAccountId;
});

