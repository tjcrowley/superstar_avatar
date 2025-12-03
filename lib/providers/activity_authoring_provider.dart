import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity_script.dart';
import '../models/power.dart';
import '../services/blockchain_service.dart';
import '../constants/app_constants.dart';
import 'avatar_provider.dart';
import 'activities_provider.dart';

/// Provider for managing activity authoring state
class ActivityAuthoringNotifier extends StateNotifier<List<ActivityScript>> {
  final BlockchainService _blockchainService = BlockchainService();
  final SharedPreferences _prefs;

  ActivityAuthoringNotifier(this._prefs) : super([]) {
    _loadAuthoredActivities();
  }

  Future<void> _loadAuthoredActivities() async {
    try {
      final activitiesJson = _prefs.getStringList('authored_activities') ?? [];
      state = activitiesJson
          .map((json) => ActivityScript.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading authored activities: $e');
    }
  }

  Future<void> _saveAuthoredActivities() async {
    try {
      final activitiesJson = state
          .map((activity) => jsonEncode(activity.toJson()))
          .toList();
      await _prefs.setStringList('authored_activities', activitiesJson);
    } catch (e) {
      debugPrint('Error saving authored activities: $e');
    }
  }

  /// Create a new activity script (Goldfire Phase 1)
  Future<String> createActivity({
    required ActivityScript activity,
    String? decentralizedStorageRef,
  }) async {
    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      // Convert ActivityType to contract enum index
      final activityTypeIndex = activity.activityType.index;
      
      // Convert PowerType to contract enum index
      final primaryPowerIndex = activity.primaryPower.index;
      final secondaryPowerIndices = activity.secondaryPowers.map((p) => p.index).toList();

      // Convert difficulty to 1-10 scale
      final difficultyValue = _convertDifficultyToValue(activity.difficulty);

      // Prepare metadata JSON
      final metadataJson = jsonEncode({
        ...activity.metadata,
        'tags': activity.tags,
        'isGroupActivity': activity.isGroupActivity,
        'minParticipants': activity.minParticipants,
        'maxParticipants': activity.maxParticipants,
      });

      // Create activity on blockchain
      final txHash = await _blockchainService.createActivityScript(
        title: activity.title,
        description: activity.description,
        instructions: activity.instructions,
        activityType: activityTypeIndex,
        primaryPower: primaryPowerIndex,
        secondaryPowers: secondaryPowerIndices,
        experienceReward: activity.experienceReward,
        difficulty: difficultyValue,
        timeLimit: 0,  // No time limit by default
        maxCompletions: 0,  // Unlimited by default
        requiresVerification: activity.metadata['requiresVerification'] ?? false,
        metadata: metadataJson,
        authorId: activity.authorId,
        decentralizedStorageRef: decentralizedStorageRef ?? '',
      );

      // Add to local state
      final newActivity = activity.copyWith(
        id: txHash.substring(0, 16),  // Use transaction hash prefix as ID
        status: ActivityStatus.published,
        decentralizedStorageRef: decentralizedStorageRef,
      );

      state = [...state, newActivity];
      await _saveAuthoredActivities();

      // Note: Activities will be refreshed from blockchain automatically
      // The activities provider will pick up the new activity on next load

      return txHash;
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  /// Update an existing activity
  Future<void> updateActivity(ActivityScript activity) async {
    try {
      state = state.map((a) => a.id == activity.id ? activity : a).toList();
      await _saveAuthoredActivities();
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  /// Delete an activity (local only, blockchain deletion would require contract update)
  Future<void> deleteActivity(String activityId) async {
    try {
      state = state.where((a) => a.id != activityId).toList();
      await _saveAuthoredActivities();
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Get activities by ActivityType
  List<ActivityScript> getActivitiesByType(ActivityType type) {
    return state.where((activity) => activity.activityType == type).toList();
  }

  /// Get activities by PowerType
  List<ActivityScript> getActivitiesByPower(PowerType power) {
    return state.where((activity) =>
        activity.primaryPower == power ||
        activity.secondaryPowers.contains(power)).toList();
  }

  /// Get activities authored by a specific author
  List<ActivityScript> getActivitiesByAuthor(String authorId) {
    return state.where((activity) => activity.authorId == authorId).toList();
  }

  int _convertDifficultyToValue(ActivityDifficulty difficulty) {
    switch (difficulty) {
      case ActivityDifficulty.beginner:
        return 2;
      case ActivityDifficulty.intermediate:
        return 5;
      case ActivityDifficulty.advanced:
        return 8;
      case ActivityDifficulty.expert:
        return 10;
    }
  }
}

// Provider
final activityAuthoringProvider = StateNotifierProvider<ActivityAuthoringNotifier, List<ActivityScript>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActivityAuthoringNotifier(prefs);
});

// Derived providers
final authoredActivitiesByTypeProvider = Provider.family<List<ActivityScript>, ActivityType>((ref, type) {
  final notifier = ref.watch(activityAuthoringProvider.notifier);
  return notifier.getActivitiesByType(type);
});

final authoredActivitiesByPowerProvider = Provider.family<List<ActivityScript>, PowerType>((ref, power) {
  final notifier = ref.watch(activityAuthoringProvider.notifier);
  return notifier.getActivitiesByPower(power);
});

