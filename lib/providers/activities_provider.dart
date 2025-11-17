import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/activity_script.dart';
import '../models/power.dart';
import '../services/blockchain_service.dart';
import 'avatar_provider.dart';

/// Provider for managing activities loaded from blockchain
class ActivitiesNotifier extends StateNotifier<AsyncValue<List<ActivityScript>>> {
  final BlockchainService _blockchainService = BlockchainService();

  ActivitiesNotifier() : super(const AsyncValue.loading()) {
    loadActivities();
  }

  /// Load all activities from blockchain
  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    
    try {
      if (!_blockchainService.isWalletConnected) {
        state = const AsyncValue.data([]);
        return;
      }

      // Get all activity IDs
      final activityIds = await _blockchainService.getAllActivityIds();
      
      if (activityIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // Fetch each activity
      final activities = <ActivityScript>[];
      for (final activityId in activityIds) {
        try {
          final activityData = await _blockchainService.getActivityScript(activityId);
          if (activityData != null && activityData['isActive'] == true) {
            final activity = _convertToActivityScript(activityData);
            if (activity != null) {
              activities.add(activity);
            }
          }
        } catch (e) {
          debugPrint('Error loading activity $activityId: $e');
          // Continue loading other activities
        }
      }

      // Sort by creation date (newest first)
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      state = AsyncValue.data(activities);
    } catch (e, stackTrace) {
      debugPrint('Error loading activities: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Convert blockchain data to ActivityScript model
  ActivityScript? _convertToActivityScript(Map<String, dynamic> data) {
    try {
      // Parse metadata JSON
      Map<String, dynamic> metadata = {};
      try {
        if (data['metadata'] != null && data['metadata'].toString().isNotEmpty) {
          metadata = jsonDecode(data['metadata'] as String) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error parsing metadata: $e');
      }

      // Convert activity type enum
      final activityTypeIndex = data['activityType'] as int;
      final activityType = ActivityType.values[activityTypeIndex.clamp(0, ActivityType.values.length - 1)];

      // Convert primary power
      final primaryPowerIndex = data['primaryPower'] as int;
      final primaryPower = PowerType.values[primaryPowerIndex.clamp(0, PowerType.values.length - 1)];

      // Convert secondary powers
      final secondaryPowerIndices = (data['secondaryPowers'] as List<dynamic>).map((e) => e as int).toList();
      final secondaryPowers = secondaryPowerIndices
          .map((i) => PowerType.values[i.clamp(0, PowerType.values.length - 1)])
          .toList();

      // Convert difficulty (1-10 scale to enum)
      final difficultyValue = data['difficulty'] as int;
      final difficulty = _convertDifficultyFromValue(difficultyValue);

      // Parse created timestamp
      final createdAtTimestamp = data['createdAt'] as int;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp * 1000);

      return ActivityScript(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String,
        instructions: data['instructions'] as String,
        activityType: activityType,
        primaryPower: primaryPower,
        secondaryPowers: secondaryPowers,
        difficulty: difficulty,
        estimatedDuration: (data['timeLimit'] as int) > 0 
            ? (data['timeLimit'] as int) ~/ 60 
            : 30, // Default 30 minutes if no time limit
        experienceReward: data['experienceReward'] as int,
        authorId: data['authorId'] as String,
        authorName: metadata['authorName'] as String? ?? 'Unknown',
        status: ActivityStatus.published,
        createdAt: createdAt,
        publishedAt: createdAt,
        tags: (metadata['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        metadata: metadata,
        decentralizedStorageRef: data['decentralizedStorageRef'] as String?,
        isGroupActivity: metadata['isGroupActivity'] as bool? ?? false,
        minParticipants: metadata['minParticipants'] as int? ?? 1,
        maxParticipants: metadata['maxParticipants'] as int? ?? 1,
      );
    } catch (e) {
      debugPrint('Error converting activity data: $e');
      return null;
    }
  }

  ActivityDifficulty _convertDifficultyFromValue(int value) {
    if (value <= 2) return ActivityDifficulty.beginner;
    if (value <= 5) return ActivityDifficulty.intermediate;
    if (value <= 8) return ActivityDifficulty.advanced;
    return ActivityDifficulty.expert;
  }

  /// Refresh activities from blockchain
  Future<void> refresh() async {
    await loadActivities();
  }
}

// Provider
final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<ActivityScript>>>((ref) {
  return ActivitiesNotifier();
});

// Derived providers
final activitiesListProvider = Provider<List<ActivityScript>>((ref) {
  final activitiesAsync = ref.watch(activitiesProvider);
  return activitiesAsync.when(
    data: (activities) => activities,
    loading: () => [],
    error: (_, __) => [],
  );
});

final activitiesLoadingProvider = Provider<bool>((ref) {
  final activitiesAsync = ref.watch(activitiesProvider);
  return activitiesAsync.isLoading;
});

final canCreateActivityProvider = FutureProvider<bool>((ref) async {
  final blockchainService = BlockchainService();
  
  if (!blockchainService.isWalletConnected) return false;
  
  // Check if user is contract owner (admin)
  final isAdmin = await blockchainService.isContractOwner();
  
  // TODO: Check if user is event producer
  // For now, allow if admin
  return isAdmin;
});

