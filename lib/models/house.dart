class House {
  final String id;
  final String name;
  final String description;
  final String? houseImage;
  final String eventId;
  final String eventName;
  final List<String> memberIds;
  final String leaderId;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, int> houseStats;
  final String? motto;
  final String? color;

  House({
    required this.id,
    required this.name,
    required this.description,
    this.houseImage,
    required this.eventId,
    required this.eventName,
    required this.memberIds,
    required this.leaderId,
    required this.createdAt,
    this.isActive = true,
    this.houseStats = const {},
    this.motto,
    this.color,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      houseImage: json['houseImage'],
      eventId: json['eventId'],
      eventName: json['eventName'],
      memberIds: List<String>.from(json['memberIds']),
      leaderId: json['leaderId'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      houseStats: Map<String, int>.from(json['houseStats'] ?? {}),
      motto: json['motto'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'houseImage': houseImage,
      'eventId': eventId,
      'eventName': eventName,
      'memberIds': memberIds,
      'leaderId': leaderId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'houseStats': houseStats,
      'motto': motto,
      'color': color,
    };
  }

  House copyWith({
    String? id,
    String? name,
    String? description,
    String? houseImage,
    String? eventId,
    String? eventName,
    List<String>? memberIds,
    String? leaderId,
    DateTime? createdAt,
    bool? isActive,
    Map<String, int>? houseStats,
    String? motto,
    String? color,
  }) {
    return House(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      houseImage: houseImage ?? this.houseImage,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      memberIds: memberIds ?? this.memberIds,
      leaderId: leaderId ?? this.leaderId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      houseStats: houseStats ?? this.houseStats,
      motto: motto ?? this.motto,
      color: color ?? this.color,
    );
  }

  int get memberCount => memberIds.length;

  bool isMember(String avatarId) => memberIds.contains(avatarId);

  bool isLeader(String avatarId) => leaderId == avatarId;

  int get totalExperience => houseStats['totalExperience'] ?? 0;

  int get averageLevel => houseStats['averageLevel'] ?? 0;

  int get completedActivities => houseStats['completedActivities'] ?? 0;

  static List<House> get defaultHouses => [
        House(
          id: 'house-1',
          name: 'House of Courage',
          description: 'A house dedicated to developing bravery and taking bold actions',
          eventId: 'event-1',
          eventName: 'Tech Conference 2024',
          memberIds: [],
          leaderId: '',
          createdAt: DateTime.now(),
          motto: 'Face your fears, embrace your power',
          color: '#FF6B6B',
        ),
        House(
          id: 'house-2',
          name: 'House of Creativity',
          description: 'A house focused on innovation and artistic expression',
          eventId: 'event-1',
          eventName: 'Tech Conference 2024',
          memberIds: [],
          leaderId: '',
          createdAt: DateTime.now(),
          motto: 'Create, inspire, transform',
          color: '#4ECDC4',
        ),
        House(
          id: 'house-3',
          name: 'House of Connection',
          description: 'A house built on meaningful relationships and community',
          eventId: 'event-1',
          eventName: 'Tech Conference 2024',
          memberIds: [],
          leaderId: '',
          createdAt: DateTime.now(),
          motto: 'Together we grow stronger',
          color: '#45B7D1',
        ),
        House(
          id: 'house-4',
          name: 'House of Insight',
          description: 'A house of wisdom and deep understanding',
          eventId: 'event-1',
          eventName: 'Tech Conference 2024',
          memberIds: [],
          leaderId: '',
          createdAt: DateTime.now(),
          motto: 'Seek truth, find wisdom',
          color: '#96CEB4',
        ),
        House(
          id: 'house-5',
          name: 'House of Kindness',
          description: 'A house of compassion and support for others',
          eventId: 'event-1',
          eventName: 'Tech Conference 2024',
          memberIds: [],
          leaderId: '',
          createdAt: DateTime.now(),
          motto: 'Kindness is our superpower',
          color: '#FFEAA7',
        ),
      ];
} 