enum PowerType {
  courage,
  creativity,
  connection,
  insight,
  kindness,
}

class Power {
  final PowerType type;
  final String name;
  final String description;
  final String icon;
  final int level;
  final int experience;
  final int experienceToNextLevel;
  final List<String> achievements;
  final DateTime lastUpdated;

  Power({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    this.level = 1,
    this.experience = 0,
    this.experienceToNextLevel = 100,
    this.achievements = const [],
    required this.lastUpdated,
  });

  factory Power.fromJson(Map<String, dynamic> json) {
    return Power(
      type: PowerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      experienceToNextLevel: json['experienceToNextLevel'] ?? 100,
      achievements: List<String>.from(json['achievements'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'icon': icon,
      'level': level,
      'experience': experience,
      'experienceToNextLevel': experienceToNextLevel,
      'achievements': achievements,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  Power copyWith({
    PowerType? type,
    String? name,
    String? description,
    String? icon,
    int? level,
    int? experience,
    int? experienceToNextLevel,
    List<String>? achievements,
    DateTime? lastUpdated,
  }) {
    return Power(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      experienceToNextLevel: experienceToNextLevel ?? this.experienceToNextLevel,
      achievements: achievements ?? this.achievements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  double get progressPercentage => experience / experienceToNextLevel;

  bool get isMaxLevel => level >= 10;

  static List<Power> get defaultPowers => [
        Power(
          type: PowerType.courage,
          name: 'Courage',
          description: 'The ability to face fears and take bold actions in social situations',
          icon: '🦁',
          lastUpdated: DateTime.now(),
        ),
        Power(
          type: PowerType.creativity,
          name: 'Creativity',
          description: 'The power to think outside the box and bring innovative ideas to life',
          icon: '🎨',
          lastUpdated: DateTime.now(),
        ),
        Power(
          type: PowerType.connection,
          name: 'Connection',
          description: 'The ability to build meaningful relationships and foster community',
          icon: '🤝',
          lastUpdated: DateTime.now(),
        ),
        Power(
          type: PowerType.insight,
          name: 'Insight',
          description: 'The power to understand others deeply and see patterns in social dynamics',
          icon: '🔍',
          lastUpdated: DateTime.now(),
        ),
        Power(
          type: PowerType.kindness,
          name: 'Kindness',
          description: 'The ability to show compassion and support others in their journey',
          icon: '💝',
          lastUpdated: DateTime.now(),
        ),
      ];
} 