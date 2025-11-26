import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/avatar.dart';
import '../models/power.dart';
import '../services/blockchain_service.dart';
import '../constants/app_constants.dart';

/// State for managing multiple avatars
class AvatarsState {
  final List<Avatar> avatars;
  final String? selectedAvatarId;

  AvatarsState({
    required this.avatars,
    this.selectedAvatarId,
  });

  Avatar? get selectedAvatar {
    if (avatars.isEmpty) return null;
    if (selectedAvatarId == null) return avatars.first;
    try {
      return avatars.firstWhere((avatar) => avatar.id == selectedAvatarId);
    } catch (e) {
      return avatars.first;
    }
  }

  Avatar? get primaryAvatar {
    if (avatars.isEmpty) return null;
    try {
      return avatars.firstWhere((avatar) => avatar.isPrimary);
    } catch (e) {
      return avatars.first;
    }
  }

  bool get hasAvatar => avatars.isNotEmpty;
  bool get hasPrimaryAvatar => primaryAvatar != null;

  AvatarsState copyWith({
    List<Avatar>? avatars,
    String? selectedAvatarId,
  }) {
    return AvatarsState(
      avatars: avatars ?? this.avatars,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
    );
  }
}

class AvatarNotifier extends StateNotifier<AvatarsState> {
  final BlockchainService _blockchainService = BlockchainService();
  final SharedPreferences _prefs;

  AvatarNotifier(this._prefs) : super(AvatarsState(avatars: [])) {
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    try {
      // Load avatars list
      final avatarsJson = _prefs.getString('${AppConstants.avatarDataKey}_list');
      if (avatarsJson != null) {
        final avatarsData = jsonDecode(avatarsJson) as List;
        final loadedAvatars = avatarsData
            .map((data) => Avatar.fromJson(data as Map<String, dynamic>))
            .toList();
        
        final selectedId = _prefs.getString('${AppConstants.avatarDataKey}_selected');
        
        state = AvatarsState(
          avatars: loadedAvatars,
          selectedAvatarId: selectedId,
        );
      } else {
        // Try to load single avatar for backward compatibility
        final avatarJson = _prefs.getString(AppConstants.avatarDataKey);
        if (avatarJson != null) {
          final avatarData = jsonDecode(avatarJson);
          final avatar = Avatar.fromJson(avatarData);
          state = AvatarsState(
            avatars: [avatar],
            selectedAvatarId: avatar.id,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading avatars: $e');
    }
  }

  Future<void> _saveAvatars() async {
    try {
      final avatarsJson = jsonEncode(
        state.avatars.map((avatar) => avatar.toJson()).toList(),
      );
      await _prefs.setString('${AppConstants.avatarDataKey}_list', avatarsJson);
      if (state.selectedAvatarId != null) {
        await _prefs.setString('${AppConstants.avatarDataKey}_selected', state.selectedAvatarId!);
      }
    } catch (e) {
      debugPrint('Error saving avatars: $e');
    }
  }

  /// Create primary avatar (first avatar, no house required)
  Future<void> createPrimaryAvatar({
    required String name,
    String? bio,
    String? avatarImage,
  }) async {
    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Identity not connected');
      }

      if (state.hasPrimaryAvatar) {
        throw Exception('Primary avatar already exists');
      }

      final walletAddress = _blockchainService.walletAddress!;
      final avatarId = _blockchainService.generateAvatarId(walletAddress, name);
      
      // Create avatar on blockchain (no houseId for primary)
      final imageUri = avatarImage ?? 'ipfs://default_avatar';
      await _blockchainService.createAvatarProfile(
        avatarId: avatarId,
        name: name,
        bio: bio ?? '',
        imageUri: imageUri,
        houseId: '', // Empty for primary avatar
        metadata: '',
      );
      
      final avatar = Avatar(
        id: avatarId,
        name: name,
        bio: bio,
        avatarImage: avatarImage ?? imageUri,
        powers: Power.defaultPowers,
        walletAddress: walletAddress,
        isPrimary: true,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final updatedAvatars = [...state.avatars, avatar];
      state = state.copyWith(
        avatars: updatedAvatars,
        selectedAvatarId: avatarId,
      );
      await _saveAvatars();
    } catch (e) {
      debugPrint('Error creating primary avatar: $e');
      // Re-throw with original message if it's already user-friendly
      final errorMessage = e.toString();
      if (errorMessage.contains('Insufficient funds') || 
          errorMessage.contains('insufficient funds')) {
        throw e; // Keep the helpful error message
      }
      throw Exception('Failed to create primary avatar: $e');
    }
  }

  /// Create additional avatar (must be associated with a house)
  Future<void> createHouseAvatar({
    required String name,
    required String houseId,
    required String houseName,
    String? bio,
    String? avatarImage,
  }) async {
    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Identity not connected');
      }

      if (!state.hasPrimaryAvatar) {
        throw Exception('Primary avatar must be created first');
      }

      if (houseId.isEmpty) {
        throw Exception('House ID is required for additional avatars');
      }

      final walletAddress = _blockchainService.walletAddress!;
      final avatarId = _blockchainService.generateAvatarId(walletAddress, name);
      
      // Create avatar on blockchain with houseId
      final imageUri = avatarImage ?? 'ipfs://default_avatar';
      await _blockchainService.createAvatarProfile(
        avatarId: avatarId,
        name: name,
        bio: bio ?? '',
        imageUri: imageUri,
        houseId: houseId,
        metadata: '',
      );
      
      // Join house with this avatar
      await _blockchainService.joinHouse(
        houseId: houseId,
        avatarId: avatarId,
        avatarName: name,
      );
      
      final avatar = Avatar(
        id: avatarId,
        name: name,
        bio: bio,
        avatarImage: avatarImage ?? imageUri,
        powers: Power.defaultPowers,
        houseId: houseId,
        houseName: houseName,
        walletAddress: walletAddress,
        isPrimary: false,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      final updatedAvatars = [...state.avatars, avatar];
      state = state.copyWith(
        avatars: updatedAvatars,
        selectedAvatarId: avatarId,
      );
      await _saveAvatars();
    } catch (e) {
      debugPrint('Error creating house avatar: $e');
      throw Exception('Failed to create house avatar: $e');
    }
  }

  /// Select an avatar to use
  Future<void> selectAvatar(String avatarId) async {
    if (!state.avatars.any((avatar) => avatar.id == avatarId)) {
      throw Exception('Avatar not found');
    }
    
    state = state.copyWith(selectedAvatarId: avatarId);
    await _prefs.setString('${AppConstants.avatarDataKey}_selected', avatarId);
  }

  Future<void> updateAvatar({
    String? name,
    String? bio,
    String? avatarImage,
  }) async {
    if (state.selectedAvatar == null) throw Exception('No avatar to update');

    try {
      final currentAvatar = state.selectedAvatar;
      if (currentAvatar == null) throw Exception('No avatar selected');
      
      final updatedAvatar = currentAvatar.copyWith(
        name: name,
        bio: bio,
        avatarImage: avatarImage,
        lastActive: DateTime.now(),
      );

      final updatedAvatars = state.avatars.map((a) => a.id == updatedAvatar.id ? updatedAvatar : a).toList();
      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    }
  }

  Future<void> addExperienceToPower(PowerType powerType, int experience) async {
    if (state.selectedAvatar == null) throw Exception('No avatar selected');

    try {
      final currentAvatar = state.selectedAvatar!;
      final currentPower = currentAvatar.getPowerByType(powerType);
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

      final updatedPowers = currentAvatar.powers.map((power) {
        return power.type == powerType ? updatedPower : power;
      }).toList();

      final updatedAvatar = currentAvatar.copyWith(
        powers: updatedPowers,
        totalExperience: currentAvatar.totalExperience + experience,
        lastActive: DateTime.now(),
      );

      final updatedAvatars = state.avatars.map((avatar) {
        return avatar.id == updatedAvatar.id ? updatedAvatar : avatar;
      }).toList();

      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();

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

      final updatedAvatars = state.avatars.map((a) {
        return a.id == avatar.id ? superstarAvatar : a;
      }).toList();

      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();
    } catch (e) {
      throw Exception('Failed to promote to Superstar Avatar: $e');
    }
  }

  Future<void> joinHouse(String houseId, String houseName) async {
    if (state.selectedAvatar == null) throw Exception('No avatar selected');

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Identity not connected');
      }

      final currentAvatar = state.selectedAvatar!;
      
      // Only primary avatar can join house (additional avatars are created with house)
      if (!currentAvatar.isPrimary) {
        throw Exception('Only primary avatar can join a house. Create a new avatar for this house.');
      }

      // Call blockchain to join house
      await _blockchainService.joinHouse(
        houseId: houseId,
        avatarId: currentAvatar.id,
        avatarName: currentAvatar.name,
      );

      final updatedAvatar = currentAvatar.copyWith(
        houseId: houseId,
        houseName: houseName,
        lastActive: DateTime.now(),
      );

      final updatedAvatars = state.avatars.map((avatar) {
        return avatar.id == updatedAvatar.id ? updatedAvatar : avatar;
      }).toList();

      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();
    } catch (e) {
      throw Exception('Failed to join house: $e');
    }
  }

  Future<void> leaveHouse() async {
    if (state.selectedAvatar == null) throw Exception('No avatar selected');

    try {
      final currentAvatar = state.selectedAvatar!;
      
      // Non-primary avatars cannot leave house (they are bound to it)
      if (!currentAvatar.isPrimary) {
        throw Exception('House-bound avatars cannot leave their house');
      }

      final updatedAvatar = currentAvatar.copyWith(
        houseId: null,
        houseName: null,
        lastActive: DateTime.now(),
      );

      final updatedAvatars = state.avatars.map((avatar) {
        return avatar.id == updatedAvatar.id ? updatedAvatar : avatar;
      }).toList();

      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();
    } catch (e) {
      throw Exception('Failed to leave house: $e');
    }
  }

  Future<void> addBadge(String badge) async {
    if (state.selectedAvatar == null) throw Exception('No avatar selected');

    try {
      final currentAvatar = state.selectedAvatar!;
      if (!currentAvatar.badges.contains(badge)) {
        final updatedBadges = [...currentAvatar.badges, badge];
        final updatedAvatar = currentAvatar.copyWith(
          badges: updatedBadges,
          lastActive: DateTime.now(),
        );

        final updatedAvatars = state.avatars.map((avatar) {
          return avatar.id == updatedAvatar.id ? updatedAvatar : avatar;
        }).toList();

        state = state.copyWith(avatars: updatedAvatars);
        await _saveAvatars();
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
    if (state.selectedAvatar == null) throw Exception('No avatar selected');

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Identity not connected');
      }

      await _blockchainService.verifyPower(
        avatarId: state.selectedAvatar!.id,
        powerType: powerType.index,
        experience: experience,
        metadata: 'Verified by: $verifierId',
      );
    } catch (e) {
      throw Exception('Failed to verify power on blockchain: $e');
    }
  }

  Future<void> syncWithBlockchain() async {
    if (state.avatars.isEmpty) return;

    try {
      if (!_blockchainService.isWalletConnected) {
        throw Exception('Identity not connected');
      }

      // Sync all avatars from blockchain
      final walletAddress = _blockchainService.walletAddress!;
      final avatarIds = await _blockchainService.getAvatarIdsByAddress(walletAddress);
      
      final updatedAvatars = <Avatar>[];
      
      for (final avatarId in avatarIds) {
        try {
          // Get existing avatar or create new one
          final existingAvatar = state.avatars.firstWhere(
            (avatar) => avatar.id == avatarId,
            orElse: () => Avatar(
              id: avatarId,
              name: '',
              powers: Power.defaultPowers,
              createdAt: DateTime.now(),
              lastActive: DateTime.now(),
            ),
          );

          // Sync avatar profile from blockchain
          final blockchainProfile = await _blockchainService.getAvatarProfile(avatarId);
          if (blockchainProfile != null) {
            // Sync power levels from blockchain
            final updatedPowers = <Power>[];
            for (final power in existingAvatar.powers) {
              try {
                final powerData = await _blockchainService.getPowerData(
                  avatarId,
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
                updatedPowers.add(power);
              }
            }

            // Sync house membership
            final houseId = await _blockchainService.getAvatarHouse(avatarId);

            final updatedAvatar = existingAvatar.copyWith(
              name: blockchainProfile['name'] as String,
              bio: blockchainProfile['bio'] as String?,
              avatarImage: blockchainProfile['imageUri'] as String?,
              powers: updatedPowers,
              houseId: (houseId?.isNotEmpty ?? false) ? houseId : null,
              isPrimary: blockchainProfile['isPrimary'] as bool? ?? false,
              lastActive: DateTime.fromMillisecondsSinceEpoch(
                (blockchainProfile['updatedAt'] as int) * 1000,
              ),
            );
            
            updatedAvatars.add(updatedAvatar);
          } else {
            updatedAvatars.add(existingAvatar);
          }
        } catch (e) {
          debugPrint('Error syncing avatar $avatarId: $e');
          // Keep existing avatar if sync fails
          final existing = state.avatars.firstWhere(
            (avatar) => avatar.id == avatarId,
            orElse: () => Avatar(
              id: avatarId,
              name: '',
              powers: Power.defaultPowers,
              createdAt: DateTime.now(),
              lastActive: DateTime.now(),
            ),
          );
          updatedAvatars.add(existing);
        }
      }

      state = state.copyWith(avatars: updatedAvatars);
      await _saveAvatars();
    } catch (e) {
      debugPrint('Error syncing with blockchain: $e');
    }
  }

  Future<void> clearAvatars() async {
    try {
      await _prefs.remove('${AppConstants.avatarDataKey}_list');
      await _prefs.remove('${AppConstants.avatarDataKey}_selected');
      await _prefs.remove(AppConstants.avatarDataKey); // Remove old single avatar key
      state = AvatarsState(avatars: []);
    } catch (e) {
      throw Exception('Failed to clear avatars: $e');
    }
  }

  // Getters for easy access to avatar data
  bool get hasAvatar => state.hasAvatar;
  bool get hasPrimaryAvatar => state.hasPrimaryAvatar;
  Avatar? get selectedAvatar => state.selectedAvatar;
  Avatar? get primaryAvatar => state.primaryAvatar;
  List<Avatar> get allAvatars => state.avatars;
  List<Avatar> get houseAvatars => state.avatars.where((a) => !a.isPrimary && a.houseId != null).toList();
  
  bool get isSuperstarAvatar => state.selectedAvatar?.isSuperstarAvatar ?? false;
  bool get canBecomeSuperstarAvatar => state.selectedAvatar?.canBecomeSuperstarAvatar ?? false;
  int get totalLevel => state.selectedAvatar?.totalLevel ?? 0;
  int get totalExperience => state.selectedAvatar?.totalExperience ?? 0;
  String? get currentHouseId => state.selectedAvatar?.houseId;
  String? get currentHouseName => state.selectedAvatar?.houseName;
  List<String> get badges => state.selectedAvatar?.badges ?? [];
  List<Power> get powers => state.selectedAvatar?.powers ?? [];

  Power? getPowerByType(PowerType type) => state.selectedAvatar?.getPowerByType(type);
  int getPowerLevel(PowerType type) => state.selectedAvatar?.getPowerLevel(type) ?? 0;
  int getPowerExperience(PowerType type) => state.selectedAvatar?.getPowerExperience(type) ?? 0;
  double getPowerProgress(PowerType type) => state.selectedAvatar?.getPowerProgress(type) ?? 0.0;
}

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Avatar provider that depends on SharedPreferences
final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) return AvatarNotifier(SharedPreferences.getInstance() as SharedPreferences);
  return AvatarNotifier(prefs);
});

// Derived providers
final hasAvatarProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider).hasAvatar;
});

final hasPrimaryAvatarProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider).hasPrimaryAvatar;
});

final selectedAvatarProvider = Provider<Avatar?>((ref) {
  return ref.watch(avatarProvider).selectedAvatar;
});

final primaryAvatarProvider = Provider<Avatar?>((ref) {
  return ref.watch(avatarProvider).primaryAvatar;
});

final allAvatarsProvider = Provider<List<Avatar>>((ref) {
  return ref.watch(avatarProvider.notifier).allAvatars;
});

final houseAvatarsProvider = Provider<List<Avatar>>((ref) {
  return ref.watch(avatarProvider.notifier).houseAvatars;
});

final isSuperstarAvatarProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider.notifier).isSuperstarAvatar;
});

final totalLevelProvider = Provider<int>((ref) {
  return ref.watch(avatarProvider.notifier).totalLevel;
});

final totalExperienceProvider = Provider<int>((ref) {
  return ref.watch(avatarProvider.notifier).totalExperience;
});

final powersProvider = Provider<List<Power>>((ref) {
  return ref.watch(avatarProvider.notifier).powers;
});

final currentHouseProvider = Provider<({String? id, String? name})>((ref) {
  final avatar = ref.watch(avatarProvider).selectedAvatar;
  return (id: avatar?.houseId, name: avatar?.houseName);
}); 