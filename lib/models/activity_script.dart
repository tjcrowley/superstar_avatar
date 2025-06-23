import 'power.dart';

enum ActivityDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum ActivityStatus {
  draft,
  published,
  reviewed,
  archived,
}

class ActivityScript {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final List<PowerType> targetPowers;
  final ActivityDifficulty difficulty;
  final int estimatedDuration; // in minutes
  final int experienceReward;
  final String authorId;
  final String authorName;
  final ActivityStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, dynamic> metadata;
  final double rating;
  final int reviewCount;
  final List<String> requiredItems;
  final bool isGroupActivity;
  final int minParticipants;
  final int maxParticipants;

  ActivityScript({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.targetPowers,
    required this.difficulty,
    required this.estimatedDuration,
    required this.experienceReward,
    required this.authorId,
    required this.authorName,
    this.status = ActivityStatus.draft,
    required this.createdAt,
    this.publishedAt,
    this.tags = const [],
    this.imageUrl,
    this.metadata = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.requiredItems = const [],
    this.isGroupActivity = false,
    this.minParticipants = 1,
    this.maxParticipants = 1,
  });

  factory ActivityScript.fromJson(Map<String, dynamic> json) {
    return ActivityScript(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      instructions: json['instructions'],
      targetPowers: (json['targetPowers'] as List)
          .map((power) => PowerType.values.firstWhere(
                (e) => e.toString().split('.').last == power,
              ))
          .toList(),
      difficulty: ActivityDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
      ),
      estimatedDuration: json['estimatedDuration'],
      experienceReward: json['experienceReward'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      status: ActivityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      requiredItems: List<String>.from(json['requiredItems'] ?? []),
      isGroupActivity: json['isGroupActivity'] ?? false,
      minParticipants: json['minParticipants'] ?? 1,
      maxParticipants: json['maxParticipants'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructions': instructions,
      'targetPowers': targetPowers
          .map((power) => power.toString().split('.').last)
          .toList(),
      'difficulty': difficulty.toString().split('.').last,
      'estimatedDuration': estimatedDuration,
      'experienceReward': experienceReward,
      'authorId': authorId,
      'authorName': authorName,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'tags': tags,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'rating': rating,
      'reviewCount': reviewCount,
      'requiredItems': requiredItems,
      'isGroupActivity': isGroupActivity,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
    };
  }

  ActivityScript copyWith({
    String? id,
    String? title,
    String? description,
    String? instructions,
    List<PowerType>? targetPowers,
    ActivityDifficulty? difficulty,
    int? estimatedDuration,
    int? experienceReward,
    String? authorId,
    String? authorName,
    ActivityStatus? status,
    DateTime? createdAt,
    DateTime? publishedAt,
    List<String>? tags,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    double? rating,
    int? reviewCount,
    List<String>? requiredItems,
    bool? isGroupActivity,
    int? minParticipants,
    int? maxParticipants,
  }) {
    return ActivityScript(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      targetPowers: targetPowers ?? this.targetPowers,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      experienceReward: experienceReward ?? this.experienceReward,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      requiredItems: requiredItems ?? this.requiredItems,
      isGroupActivity: isGroupActivity ?? this.isGroupActivity,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  bool get isPublished => status == ActivityStatus.published;

  bool get isReviewed => status == ActivityStatus.reviewed;

  String get difficultyLabel {
    switch (difficulty) {
      case ActivityDifficulty.beginner:
        return 'Beginner';
      case ActivityDifficulty.intermediate:
        return 'Intermediate';
      case ActivityDifficulty.advanced:
        return 'Advanced';
      case ActivityDifficulty.expert:
        return 'Expert';
    }
  }

  String get durationLabel {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}m';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  static List<ActivityScript> get sampleActivities => [
        ActivityScript(
          id: 'activity-1',
          title: 'The Courageous Introduction',
          description: 'Approach someone new and introduce yourself with confidence',
          instructions: 'Find someone you don\'t know at the event and introduce yourself. Share something interesting about yourself and ask them a thoughtful question.',
          targetPowers: [PowerType.courage, PowerType.connection],
          difficulty: ActivityDifficulty.beginner,
          estimatedDuration: 5,
          experienceReward: 25,
          authorId: 'system',
          authorName: 'Superstar Avatar System',
          status: ActivityStatus.published,
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          publishedAt: DateTime.now().subtract(Duration(days: 30)),
          tags: ['introduction', 'networking', 'confidence'],
          isGroupActivity: false,
        ),
        ActivityScript(
          id: 'activity-2',
          title: 'Creative Problem Solving',
          description: 'Work with your house to solve a creative challenge',
          instructions: 'Your house will be given a creative challenge. Work together to come up with innovative solutions and present your ideas.',
          targetPowers: [PowerType.creativity, PowerType.connection],
          difficulty: ActivityDifficulty.intermediate,
          estimatedDuration: 30,
          experienceReward: 50,
          authorId: 'system',
          authorName: 'Superstar Avatar System',
          status: ActivityStatus.published,
          createdAt: DateTime.now().subtract(Duration(days: 25)),
          publishedAt: DateTime.now().subtract(Duration(days: 25)),
          tags: ['teamwork', 'innovation', 'presentation'],
          isGroupActivity: true,
          minParticipants: 3,
          maxParticipants: 8,
        ),
        ActivityScript(
          id: 'activity-3',
          title: 'Kindness Chain',
          description: 'Perform three acts of kindness and inspire others to do the same',
          instructions: 'Complete three different acts of kindness during the event. Document each act and encourage others to continue the chain of kindness.',
          targetPowers: [PowerType.kindness, PowerType.connection],
          difficulty: ActivityDifficulty.beginner,
          estimatedDuration: 45,
          experienceReward: 40,
          authorId: 'system',
          authorName: 'Superstar Avatar System',
          status: ActivityStatus.published,
          createdAt: DateTime.now().subtract(Duration(days: 20)),
          publishedAt: DateTime.now().subtract(Duration(days: 20)),
          tags: ['kindness', 'community', 'inspiration'],
          isGroupActivity: false,
        ),
      ];
} 