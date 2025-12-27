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

  AvatarNotifier(this._prefs) : super(_loadInitialState(_prefs)) {
    // State is initialized directly in super() to prevent rebuild loops
  }

  static AvatarsState _loadInitialState(SharedPreferences prefs) {
    try {
      debugPrint('AvatarNotifier: Loading avatar state from SharedPreferences...');
      
      // Load avatars list
      final avatarsJson = prefs.getString('${AppConstants.avatarDataKey}_list');
      debugPrint('AvatarNotifier: avatarsJson key = ${AppConstants.avatarDataKey}_list');
      debugPrint('AvatarNotifier: avatarsJson value = ${avatarsJson != null ? "found (${avatarsJson.length} chars)" : "null"}');
      
      if (avatarsJson != null) {
        final avatarsData = jsonDecode(avatarsJson) as List;
        final loadedAvatars = avatarsData
            .map((data) => Avatar.fromJson(data as Map<String, dynamic>))
            .toList();
        
        debugPrint('AvatarNotifier: Loaded ${loadedAvatars.length} avatar(s) from list');
        for (var avatar in loadedAvatars) {
          debugPrint('AvatarNotifier: - Avatar ID: ${avatar.id}, Name: ${avatar.name}, IsPrimary: ${avatar.isPrimary}');
        }
        
        final selectedId = prefs.getString('${AppConstants.avatarDataKey}_selected');
        debugPrint('AvatarNotifier: Selected avatar ID: $selectedId');
        
        final state = AvatarsState(
          avatars: loadedAvatars,
          selectedAvatarId: selectedId,
        );
        debugPrint('AvatarNotifier: hasAvatar = ${state.hasAvatar}');
        return state;
      } else {
        // Try to load single avatar for backward compatibility
        debugPrint('AvatarNotifier: No list found, trying single avatar key...');
        final avatarJson = prefs.getString(AppConstants.avatarDataKey);
        debugPrint('AvatarNotifier: Single avatar key = ${AppConstants.avatarDataKey}');
        debugPrint('AvatarNotifier: Single avatar value = ${avatarJson != null ? "found (${avatarJson.length} chars)" : "null"}');
        
        if (avatarJson != null) {
          final avatarData = jsonDecode(avatarJson);
          final avatar = Avatar.fromJson(avatarData);
          debugPrint('AvatarNotifier: Loaded single avatar - ID: ${avatar.id}, Name: ${avatar.name}, IsPrimary: ${avatar.isPrimary}');
          
          final state = AvatarsState(
            avatars: [avatar],
            selectedAvatarId: avatar.id,
          );
          debugPrint('AvatarNotifier: hasAvatar = ${state.hasAvatar}');
          return state;
        }
      }
      
      debugPrint('AvatarNotifier: No avatars found in SharedPreferences');
    } catch (e, stack) {
      debugPrint('AvatarNotifier: Error loading avatars: $e');
      debugPrint('AvatarNotifier: Stack: $stack');
    }
    
    debugPrint('AvatarNotifier: Returning empty state');
    return AvatarsState(avatars: []);
  }

  Future<void> _saveAvatars() async {
    try {
      debugPrint('AvatarNotifier: Saving ${state.avatars.length} avatar(s)...');
      final avatarsJson = jsonEncode(
        state.avatars.map((avatar) => avatar.toJson()).toList(),
      );
      await _prefs.setString('${AppConstants.avatarDataKey}_list', avatarsJson);
      debugPrint('AvatarNotifier: Saved avatars list (${avatarsJson.length} chars)');
      
      if (state.selectedAvatarId != null) {
        await _prefs.setString('${AppConstants.avatarDataKey}_selected', state.selectedAvatarId!);
        debugPrint('AvatarNotifier: Saved selected avatar ID: ${state.selectedAvatarId}');
      }
      
      debugPrint('AvatarNotifier: Avatar state saved successfully');
    } catch (e, stack) {
      debugPrint('AvatarNotifier: Error saving avatars: $e');
      debugPrint('AvatarNotifier: Stack: $stack');
    }
  }

  /// Create primary avatar (first avatar, no house required)
  Future<void> createPrimaryAvatar({
    required String name,
    String? bio,
    String? avatarImage,
  }) async {
    try {
      // Debug: Check wallet connection status
      debugPrint('AvatarNotifier: Checking wallet connection...');
      debugPrint('AvatarNotifier: walletAddress = ${_blockchainService.walletAddress}');
      debugPrint('AvatarNotifier: isWalletConnected = ${_blockchainService.isWalletConnected}');
      
      if (!_blockchainService.isWalletConnected) {
        debugPrint('AvatarNotifier: Wallet not connected, throwing error');
        throw Exception('Identity not connected');
      }

      // First, check if avatars exist on blockchain but not in local state
      if (state.avatars.isEmpty) {
        debugPrint('AvatarNotifier: Local state empty, checking blockchain for existing avatars...');
        await loadAvatarsFromBlockchain();
        
        // After loading, check again if we now have avatars
        if (state.hasAvatar) {
          debugPrint('AvatarNotifier: Found existing avatar(s) on blockchain, cannot create new primary avatar');
          throw Exception('Avatar already exists. Please use your existing avatar.');
        }
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

  /// Load avatars from blockchain when local state is empty
  Future<void> loadAvatarsFromBlockchain() async {
    try {
      if (!_blockchainService.isWalletConnected) {
        debugPrint('AvatarNotifier: Cannot load avatars - wallet not connected');
        return;
      }

      debugPrint('AvatarNotifier: Loading avatars from blockchain...');
      
      // Get all avatar IDs for this wallet address
      final walletAddress = _blockchainService.walletAddress!;
      final avatarIds = await _blockchainService.getAvatarIdsByAddress(walletAddress);
      
      debugPrint('AvatarNotifier: Found ${avatarIds.length} avatar(s) on blockchain');
      
      if (avatarIds.isEmpty) {
        debugPrint('AvatarNotifier: No avatars found on blockchain');
        return;
      }
      
      final loadedAvatars = <Avatar>[];
      
      for (final avatarId in avatarIds) {
        try {
          debugPrint('AvatarNotifier: Loading avatar $avatarId from blockchain...');
          
          // Get avatar profile from blockchain
          final blockchainProfile = await _blockchainService.getAvatarProfile(avatarId);
          if (blockchainProfile == null) {
            debugPrint('AvatarNotifier: Avatar $avatarId profile not found on blockchain');
            continue;
          }
          
          // Get power levels from blockchain
          final updatedPowers = <Power>[];
          for (final powerType in PowerType.values) {
            try {
              final powerData = await _blockchainService.getPowerData(
                avatarId,
                powerType.index,
              );
              final blockchainLevel = powerData['level'] as int;
              final blockchainExperience = powerData['experience'] as int? ?? 0;
              
              // Get default power to get name, description, and icon
              final defaultPower = Power.defaultPowers.firstWhere((p) => p.type == powerType);
              
              updatedPowers.add(Power(
                type: powerType,
                name: defaultPower.name,
                description: defaultPower.description,
                icon: defaultPower.icon,
                level: blockchainLevel,
                experience: blockchainExperience,
                experienceToNextLevel: AppConstants.levelExperienceRequirements[blockchainLevel] ?? 100,
                lastUpdated: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('AvatarNotifier: Error loading power ${powerType.name} for avatar $avatarId: $e');
              // Use default power if loading fails
              updatedPowers.add(Power.defaultPowers.firstWhere((p) => p.type == powerType));
            }
          }
          
          // Get house membership
          String? houseId;
          String? houseName;
          try {
            houseId = await _blockchainService.getAvatarHouse(avatarId);
            if (houseId != null && houseId.isNotEmpty) {
              // Try to get house name (if available)
              // For now, we'll just use the houseId
              houseName = houseId; // TODO: Fetch actual house name if available
            }
          } catch (e) {
            debugPrint('AvatarNotifier: Error loading house for avatar $avatarId: $e');
          }
          
          final isPrimary = blockchainProfile['isPrimary'] as bool? ?? false;
          final updatedAt = blockchainProfile['updatedAt'] as int? ?? 0;
          
          final avatar = Avatar(
            id: avatarId,
            name: blockchainProfile['name'] as String,
            bio: blockchainProfile['bio'] as String?,
            avatarImage: blockchainProfile['imageUri'] as String?,
            powers: updatedPowers,
            walletAddress: walletAddress,
            houseId: houseId,
            houseName: houseName,
            isPrimary: isPrimary,
            createdAt: DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000),
            lastActive: DateTime.fromMillisecondsSinceEpoch(updatedAt * 1000),
          );
          
          loadedAvatars.add(avatar);
          debugPrint('AvatarNotifier: Loaded avatar $avatarId: ${avatar.name} (Primary: $isPrimary)');
        } catch (e, stack) {
          debugPrint('AvatarNotifier: Error loading avatar $avatarId: $e');
          debugPrint('AvatarNotifier: Stack: $stack');
        }
      }
      
      if (loadedAvatars.isNotEmpty) {
        // Sort: primary avatar first
        loadedAvatars.sort((a, b) {
          if (a.isPrimary && !b.isPrimary) return -1;
          if (!a.isPrimary && b.isPrimary) return 1;
          return 0;
        });
        
        // Select primary avatar or first avatar
        final selectedId = loadedAvatars.firstWhere(
          (a) => a.isPrimary,
          orElse: () => loadedAvatars.first,
        ).id;
        
        state = state.copyWith(
          avatars: loadedAvatars,
          selectedAvatarId: selectedId,
        );
        await _saveAvatars();
        debugPrint('AvatarNotifier: Loaded ${loadedAvatars.length} avatar(s) from blockchain');
      }
    } catch (e, stack) {
      debugPrint('AvatarNotifier: Error loading avatars from blockchain: $e');
      debugPrint('AvatarNotifier: Stack: $stack');
    }
  }

  Future<void> syncWithBlockchain() async {
    if (state.avatars.isEmpty) {
      // If local state is empty, try loading from blockchain first
      await loadAvatarsFromBlockchain();
      return;
    }

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

// Global variable to store SharedPreferences instance (set in main.dart)
// This is accessed via a getter function exported from main.dart
SharedPreferences? _cachedSharedPreferences;

// Setter function to cache the SharedPreferences instance (called from main.dart)
void setSharedPreferencesInstance(SharedPreferences prefs) {
  _cachedSharedPreferences = prefs;
}

// SharedPreferences provider - using a regular Provider with cached instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  if (_cachedSharedPreferences == null) {
    throw Exception(
      'SharedPreferences not initialized. '
      'Please ensure SharedPreferences.getInstance() is called in main() before the app starts.'
    );
  }
  return _cachedSharedPreferences!;
});

// Avatar provider that depends on SharedPreferences
// Use ref.read instead of ref.watch to prevent recreation loops
final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarsState>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
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