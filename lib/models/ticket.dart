class Ticket {
  final String ticketId;
  final String eventId;
  final String avatarId;
  final String buyerAddress;
  final DateTime purchaseTime;
  final int price; // Price in smallest currency unit (cents)
  final bool isValid;
  final bool isUsed;
  final String stripePaymentIntentId;
  final String? qrCodeHash;
  final DateTime? checkedInAt;
  final String? checkedInBy;
  final Map<String, dynamic>? metadata;

  Ticket({
    required this.ticketId,
    required this.eventId,
    required this.avatarId,
    required this.buyerAddress,
    required this.purchaseTime,
    required this.price,
    required this.isValid,
    required this.isUsed,
    required this.stripePaymentIntentId,
    this.qrCodeHash,
    this.checkedInAt,
    this.checkedInBy,
    this.metadata,
  });

  double get priceInDollars => price / 100.0;
  bool get canBeUsed => isValid && !isUsed;
  bool get isCheckedIn => isUsed && checkedInAt != null;

  Ticket copyWith({
    String? ticketId,
    String? eventId,
    String? avatarId,
    String? buyerAddress,
    DateTime? purchaseTime,
    int? price,
    bool? isValid,
    bool? isUsed,
    String? stripePaymentIntentId,
    String? qrCodeHash,
    DateTime? checkedInAt,
    String? checkedInBy,
    Map<String, dynamic>? metadata,
  }) {
    return Ticket(
      ticketId: ticketId ?? this.ticketId,
      eventId: eventId ?? this.eventId,
      avatarId: avatarId ?? this.avatarId,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      price: price ?? this.price,
      isValid: isValid ?? this.isValid,
      isUsed: isUsed ?? this.isUsed,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'avatarId': avatarId,
      'buyerAddress': buyerAddress,
      'purchaseTime': purchaseTime.toIso8601String(),
      'price': price,
      'isValid': isValid,
      'isUsed': isUsed,
      'stripePaymentIntentId': stripePaymentIntentId,
      'qrCodeHash': qrCodeHash,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'checkedInBy': checkedInBy,
      'metadata': metadata,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticketId'] as String,
      eventId: json['eventId'] as String,
      avatarId: json['avatarId'] as String,
      buyerAddress: json['buyerAddress'] as String,
      purchaseTime: DateTime.parse(json['purchaseTime'] as String),
      price: json['price'] as int,
      isValid: json['isValid'] as bool,
      isUsed: json['isUsed'] as bool,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String,
      qrCodeHash: json['qrCodeHash'] as String?,
      checkedInAt: json['checkedInAt'] != null 
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      checkedInBy: json['checkedInBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'Ticket(ticketId: $ticketId, eventId: $eventId, isValid: $isValid, isUsed: $isUsed)';
  }
}

