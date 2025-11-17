import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/avatar.dart';
import '../models/power.dart';
import '../services/blockchain_service.dart';
import '../constants/app_constants.dart';

class AvatarNotifier extends StateNotifier<Avatar?> {
  final BlockchainService _blockchainService = BlockchainService();
  final SharedPreferences _prefs;

  AvatarNotifier(this._prefs) : super(null) {
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final avatarJson = _prefs.getString(AppConstants.avatarDataKey);
      if (avatarJson != null) {
        final avatarData = jsonDecode(avatarJson);
        state = Avatar.fromJson(avatarData);
      }
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }
  }

  Future<void> _saveAvatar(Avatar avatar) async {
    try {
      final avatarJson = jsonEncode(avatar.toJson());
      await _prefs.setString(AppConstants.avatarDataKey, avatarJson);
      state = avatar;
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }

  Future<void> createAvatar({
    required String name,
    String? bio,
    String? avatarImage,
  }) async {
    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      final walletAddress = _blockchainService.walletAddress!;
      final avatarId = _blockchainService.generateAvatarId(walletAddress, name);
      
      // Create avatar on blockchain
      final imageUri = avatarImage ?? 'ipfs://default_avatar';
      await _blockchainService.createAvatarProfile(
        avatarId: avatarId,
        name: name,
        bio: bio ?? '',
        imageUri: imageUri,
        metadata: '',
      );
      
      final avatar = Avatar(
        id: avatarId,
        name: name,
        bio: bio,
        avatarImage: avatarImage ?? imageUri,
        powers: Power.defaultPowers,
        walletAddress: walletAddress,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await _saveAvatar(avatar);
    } catch (e) {
      debugPrint('Error creating avatar: $e');
      throw Exception('Failed to create avatar: $e');
    }
  }

  Future<void> updateAvatar({
    String? name,
    String? bio,
    String? avatarImage,
  }) async {
    if (state == null) throw Exception('No avatar to update');

    try {
      final updatedAvatar = state!.copyWith(
        name: name,
        bio: bio,
        avatarImage: avatarImage,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(updatedAvatar);
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    }
  }

  Future<void> addExperienceToPower(PowerType powerType, int experience) async {
    if (state == null) throw Exception('No avatar found');

    try {
      final currentPower = state!.getPowerByType(powerType);
      if (currentPower == null) throw Exception('Power not found');

      int newExperience = currentPower.experience + experience;
      int newLevel = currentPower.level;
      int experienceToNextLevel = currentPower.experienceToNextLevel;

      // Check if level up is possible
      while (newExperience >= experienceToNextLevel && newLevel < 10) {
        newExperience -= experienceToNextLevel;
        newLevel++;
        experienceToNextLevel = AppConstants.levelExperienceRequirements[newLevel] ?? 100;
      }

      final updatedPower = currentPower.copyWith(
        level: newLevel,
        experience: newExperience,
        experienceToNextLevel: experienceToNextLevel,
        lastUpdated: DateTime.now(),
      );

      final updatedPowers = state!.powers.map((power) {
        return power.type == powerType ? updatedPower : power;
      }).toList();

      final updatedAvatar = state!.copyWith(
        powers: updatedPowers,
        totalExperience: state!.totalExperience + experience,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(updatedAvatar);

      // Check if avatar can become Superstar Avatar
      if (updatedAvatar.canBecomeSuperstarAvatar) {
        await _promoteToSuperstarAvatar(updatedAvatar);
      }
    } catch (e) {
      throw Exception('Failed to add experience: $e');
    }
  }

  Future<void> _promoteToSuperstarAvatar(Avatar avatar) async {
    try {
      final superstarAvatar = avatar.copyWith(
        isSuperstarAvatar: true,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(superstarAvatar);
    } catch (e) {
      throw Exception('Failed to promote to Superstar Avatar: $e');
    }
  }

  Future<void> joinHouse(String houseId, String houseName) async {
    if (state == null) throw Exception('No avatar found');

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      // Call blockchain to join house
      await _blockchainService.joinHouse(
        houseId: houseId,
        avatarId: state!.id,
        avatarName: state!.name,
      );

      final updatedAvatar = state!.copyWith(
        houseId: houseId,
        houseName: houseName,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(updatedAvatar);
    } catch (e) {
      throw Exception('Failed to join house: $e');
    }
  }

  Future<void> leaveHouse() async {
    if (state == null) throw Exception('No avatar found');

    try {
      final updatedAvatar = state!.copyWith(
        houseId: null,
        houseName: null,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(updatedAvatar);
    } catch (e) {
      throw Exception('Failed to leave house: $e');
    }
  }

  Future<void> addBadge(String badge) async {
    if (state == null) throw Exception('No avatar found');

    try {
      if (!state!.badges.contains(badge)) {
        final updatedBadges = [...state!.badges, badge];
        final updatedAvatar = state!.copyWith(
          badges: updatedBadges,
          lastActive: DateTime.now(),
        );

        await _saveAvatar(updatedAvatar);
      }
    } catch (e) {
      throw Exception('Failed to add badge: $e');
    }
  }

  Future<void> verifyPowerOnBlockchain({
    required PowerType powerType,
    required int experience,
    required String verifierId,
  }) async {
    if (state == null) throw Exception('No avatar found');

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      await _blockchainService.verifyPower(
        avatarId: state!.id,
        powerType: powerType.index,
        experience: experience,
        metadata: 'Verified by: $verifierId',
      );
    } catch (e) {
      throw Exception('Failed to verify power on blockchain: $e');
    }
  }

  Future<void> syncWithBlockchain() async {
    if (state == null) return;

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Wallet not connected');
      }

      // Sync avatar profile from blockchain
      try {
        final blockchainProfile = await _blockchainService.getAvatarProfile(state!.id);
        if (blockchainProfile != null) {
          // Update local avatar with blockchain data
          final updatedAvatar = state!.copyWith(
            name: blockchainProfile['name'] as String,
            bio: blockchainProfile['bio'] as String?,
            avatarImage: blockchainProfile['imageUri'] as String?,
            lastActive: DateTime.fromMillisecondsSinceEpoch(
              (blockchainProfile['updatedAt'] as int) * 1000,
            ),
          );
          await _saveAvatar(updatedAvatar);
        }
      } catch (e) {
        debugPrint('Error syncing avatar profile from blockchain: $e');
      }

      // Sync power levels from blockchain
      final updatedPowers = <Power>[];
      for (final power in state!.powers) {
        try {
          final powerData = await _blockchainService.getPowerData(
            state!.id,
            power.type.index,
          );
          final blockchainLevel = powerData['level'] as int;

          if (blockchainLevel > power.level) {
            updatedPowers.add(power.copyWith(
              level: blockchainLevel,
              lastUpdated: DateTime.now(),
            ));
          } else {
            updatedPowers.add(power);
          }
        } catch (e) {
          // If blockchain call fails, keep existing power
          updatedPowers.add(power);
        }
      }

      // Sync house membership
      final houseId = await _blockchainService.getAvatarHouse(state!.id);

      final updatedAvatar = state!.copyWith(
        powers: updatedPowers,
        houseId: houseId,
        lastActive: DateTime.now(),
      );

      await _saveAvatar(updatedAvatar);
    } catch (e) {
      debugPrint('Error syncing with blockchain: $e');
    }
  }

  Future<void> clearAvatar() async {
    try {
      await _prefs.remove(AppConstants.avatarDataKey);
      state = null;
    } catch (e) {
      throw Exception('Failed to clear avatar: $e');
    }
  }

  // Getters for easy access to avatar data
  bool get hasAvatar => state != null;
  bool get isSuperstarAvatar => state?.isSuperstarAvatar ?? false;
  bool get canBecomeSuperstarAvatar => state?.canBecomeSuperstarAvatar ?? false;
  int get totalLevel => state?.totalLevel ?? 0;
  int get totalExperience => state?.totalExperience ?? 0;
  String? get currentHouseId => state?.houseId;
  String? get currentHouseName => state?.houseName;
  List<String> get badges => state?.badges ?? [];
  List<Power> get powers => state?.powers ?? [];

  Power? getPowerByType(PowerType type) => state?.getPowerByType(type);
  int getPowerLevel(PowerType type) => state?.getPowerLevel(type) ?? 0;
  int getPowerExperience(PowerType type) => state?.getPowerExperience(type) ?? 0;
  double getPowerProgress(PowerType type) => state?.getPowerProgress(type) ?? 0.0;
}

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Avatar provider that depends on SharedPreferences
final avatarProvider = StateNotifierProvider<AvatarNotifier, Avatar?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) return AvatarNotifier(SharedPreferences.getInstance() as SharedPreferences);
  return AvatarNotifier(prefs);
});

// Derived providers
final hasAvatarProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider) != null;
});

final isSuperstarAvatarProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider)?.isSuperstarAvatar ?? false;
});

final totalLevelProvider = Provider<int>((ref) {
  return ref.watch(avatarProvider)?.totalLevel ?? 0;
});

final totalExperienceProvider = Provider<int>((ref) {
  return ref.watch(avatarProvider)?.totalExperience ?? 0;
});

final powersProvider = Provider<List<Power>>((ref) {
  return ref.watch(avatarProvider)?.powers ?? [];
});

final currentHouseProvider = Provider<({String? id, String? name})>((ref) {
  final avatar = ref.watch(avatarProvider);
  return (id: avatar?.houseId, name: avatar?.houseName);
}); 