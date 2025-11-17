import 'event.dart';
import '../services/geocoding_service.dart';

/// Event model extended with location coordinates
class EventWithLocation {
  final Event event;
  final LocationCoordinates? coordinates;

  EventWithLocation({
    required this.event,
    this.coordinates,
  });

  bool get hasCoordinates => coordinates != null;

  EventWithLocation copyWith({
    Event? event,
    LocationCoordinates? coordinates,
  }) {
    return EventWithLocation(
      event: event ?? this.event,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

