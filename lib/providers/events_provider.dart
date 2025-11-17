import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/event_with_location.dart';
import '../services/blockchain_service.dart';
import '../services/geocoding_service.dart';
import '../providers/event_producer_provider.dart';

/// Provider for managing events from EventListings contract
class EventsNotifier extends StateNotifier<AsyncValue<List<EventWithLocation>>> {
  final BlockchainService _blockchainService = BlockchainService();
  final GeocodingService _geocodingService = GeocodingService();

  EventsNotifier() : super(const AsyncValue.loading()) {
    loadEvents();
  }

  /// Load all events from all producers
  Future<void> loadEvents() async {
    state = const AsyncValue.loading();

    try {
      // Get all producers first
      // Note: This assumes we have a way to get all producers
      // For now, we'll need to track producers or use event logs
      // This is a placeholder - you'll need to implement getAllProducers
      
      final events = <EventWithLocation>[];
      
      // TODO: Implement getAllProducers or use event logs to get all events
      // For now, this is a structure that can be filled in
      
      // Example: If we have producer IDs, we can fetch their events
      // final producerIds = await _getAllProducerIds();
      // for (final producerId in producerIds) {
      //   final eventIds = await _blockchainService.getProducerEvents(producerId);
      //   for (final eventId in eventIds) {
      //     final event = await _blockchainService.getEvent(eventId);
      //     if (event != null && event.isActive && !event.isCancelled && event.isUpcoming) {
      //       final coordinates = await _geocodingService.getCoordinatesFromAddress(event.location);
      //       events.add(EventWithLocation(event: event, coordinates: coordinates));
      //     }
      //   }
      // }
      
      state = AsyncValue.data(events);
    } catch (e, stackTrace) {
      debugPrint('Error loading events: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh events
  Future<void> refresh() async {
    await loadEvents();
  }

  /// Get events filtered by location (within radius)
  List<EventWithLocation> getEventsNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) {
    return state.value?.where((eventWithLocation) {
      if (eventWithLocation.coordinates == null) return false;
      
      final coords = eventWithLocation.coordinates!;
      final distance = _calculateDistance(
        latitude,
        longitude,
        coords.latitude,
        coords.longitude,
      );
      
      return distance <= radiusKm;
    }).toList() ?? [];
  }

  /// Calculate distance between two coordinates in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}

// Provider
final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventWithLocation>>>((ref) {
  return EventsNotifier();
});

// Filtered providers
final upcomingEventsProvider = Provider<List<EventWithLocation>>((ref) {
  final events = ref.watch(eventsProvider).value ?? [];
  return events.where((e) => e.event.isUpcoming).toList();
});

final nearbyEventsProvider = Provider.family<List<EventWithLocation>, Map<String, double>>((ref, location) {
  final events = ref.watch(eventsProvider).value ?? [];
  final notifier = ref.read(eventsProvider.notifier);
  
  return notifier.getEventsNearby(
    latitude: location['latitude']!,
    longitude: location['longitude']!,
    radiusKm: location['radius'] ?? 50.0,
  );
});

