enum EventCategory {
  concert,
  party,
  conference,
  workshop,
  festival,
  sports,
  theater,
  other,
}

class Event {
  final String id;
  final String producerId;
  final String title;
  final String description;
  final String venue;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int ticketPrice; // Price in smallest currency unit (cents)
  final int maxTickets;
  final int ticketsSold;
  final DateTime createdAt;
  final bool isActive;
  final bool isCancelled;
  final String? imageUri;
  final EventCategory category;
  final Map<String, dynamic>? metadata;

  Event({
    required this.id,
    required this.producerId,
    required this.title,
    required this.description,
    required this.venue,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.ticketPrice,
    required this.maxTickets,
    required this.ticketsSold,
    required this.createdAt,
    required this.isActive,
    required this.isCancelled,
    this.imageUri,
    required this.category,
    this.metadata,
  });

  bool get isSoldOut => ticketsSold >= maxTickets;
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isOngoing => 
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  int get ticketsRemaining => maxTickets - ticketsSold;
  double get ticketPriceInDollars => ticketPrice / 100.0;

  Event copyWith({
    String? id,
    String? producerId,
    String? title,
    String? description,
    String? venue,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? ticketPrice,
    int? maxTickets,
    int? ticketsSold,
    DateTime? createdAt,
    bool? isActive,
    bool? isCancelled,
    String? imageUri,
    EventCategory? category,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      maxTickets: maxTickets ?? this.maxTickets,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isCancelled: isCancelled ?? this.isCancelled,
      imageUri: imageUri ?? this.imageUri,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producerId': producerId,
      'title': title,
      'description': description,
      'venue': venue,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'ticketPrice': ticketPrice,
      'maxTickets': maxTickets,
      'ticketsSold': ticketsSold,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'isCancelled': isCancelled,
      'imageUri': imageUri,
      'category': category.index,
      'metadata': metadata,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      producerId: json['producerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      venue: json['venue'] as String,
      location: json['location'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      ticketPrice: json['ticketPrice'] as int,
      maxTickets: json['maxTickets'] as int,
      ticketsSold: json['ticketsSold'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      isCancelled: json['isCancelled'] as bool,
      imageUri: json['imageUri'] as String?,
      category: EventCategory.values[json['category'] as int],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, startTime: $startTime)';
  }
}

