import 'power.dart';

class Avatar {
  final String id;
  final String name;
  final String? avatarImage;
  final String? bio;
  final List<Power> powers;
  final String? houseId;
  final String? houseName;
  final int totalExperience;
  final List<String> badges;
  final bool isSuperstarAvatar;
  final bool isPrimary; // True if this is the primary (first) avatar
  final DateTime createdAt;
  final DateTime lastActive;
  final String? walletAddress;
  final String? did;

  Avatar({
    required this.id,
    required this.name,
    this.avatarImage,
    this.bio,
    required this.powers,
    this.houseId,
    this.houseName,
    this.totalExperience = 0,
    this.badges = const [],
    this.isSuperstarAvatar = false,
    this.isPrimary = false,
    required this.createdAt,
    required this.lastActive,
    this.walletAddress,
    this.did,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
      avatarImage: json['avatarImage'],
      bio: json['bio'],
      powers: (json['powers'] as List)
          .map((powerJson) => Power.fromJson(powerJson))
          .toList(),
      houseId: json['houseId'],
      houseName: json['houseName'],
      totalExperience: json['totalExperience'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      isSuperstarAvatar: json['isSuperstarAvatar'] ?? false,
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
      walletAddress: json['walletAddress'],
      did: json['did'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarImage': avatarImage,
      'bio': bio,
      'powers': powers.map((power) => power.toJson()).toList(),
      'houseId': houseId,
      'houseName': houseName,
      'totalExperience': totalExperience,
      'badges': badges,
      'isSuperstarAvatar': isSuperstarAvatar,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'walletAddress': walletAddress,
      'did': did,
    };
  }

  Avatar copyWith({
    String? id,
    String? name,
    String? avatarImage,
    String? bio,
    List<Power>? powers,
    String? houseId,
    String? houseName,
    int? totalExperience,
    List<String>? badges,
    bool? isSuperstarAvatar,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? lastActive,
    String? walletAddress,
    String? did,
  }) {
    return Avatar(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarImage: avatarImage ?? this.avatarImage,
      bio: bio ?? this.bio,
      powers: powers ?? this.powers,
      houseId: houseId ?? this.houseId,
      houseName: houseName ?? this.houseName,
      totalExperience: totalExperience ?? this.totalExperience,
      badges: badges ?? this.badges,
      isSuperstarAvatar: isSuperstarAvatar ?? this.isSuperstarAvatar,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      walletAddress: walletAddress ?? this.walletAddress,
      did: did ?? this.did,
    );
  }

  int get totalLevel => powers.fold(0, (sum, power) => sum + power.level);

  bool get hasAllPowersMaxed => powers.every((power) => power.isMaxLevel);

  Power? getPowerByType(PowerType type) {
    try {
      return powers.firstWhere((power) => power.type == type);
    } catch (e) {
      return null;
    }
  }

  int getPowerLevel(PowerType type) {
    return getPowerByType(type)?.level ?? 0;
  }

  int getPowerExperience(PowerType type) {
    return getPowerByType(type)?.experience ?? 0;
  }

  double getPowerProgress(PowerType type) {
    final power = getPowerByType(type);
    if (power == null) return 0.0;
    return power.progressPercentage;
  }

  bool get canBecomeSuperstarAvatar {
    return hasAllPowersMaxed && !isSuperstarAvatar;
  }

  String get status {
    if (isSuperstarAvatar) return 'Superstar Avatar';
    if (hasAllPowersMaxed) return 'Ready for Superstar';
    return 'Avatar in Training';
  }
} 