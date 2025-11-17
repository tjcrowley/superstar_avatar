import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/event.dart';
import '../models/event_with_location.dart';
import '../providers/events_provider.dart';
import '../services/geocoding_service.dart';

/// Event discovery screen with map overlay and event list
class EventDiscoveryScreen extends ConsumerStatefulWidget {
  const EventDiscoveryScreen({super.key});

  @override
  ConsumerState<EventDiscoveryScreen> createState() => _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends ConsumerState<EventDiscoveryScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isMapView = true;
  double _searchRadius = 50.0; // km

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Move map to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          12.0,
        ),
      );

      // Update markers
      _updateMarkers();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _updateMarkers() {
    final events = ref.read(eventsProvider).value ?? [];
    final markers = <Marker>{};

    for (int i = 0; i < events.length; i++) {
      final eventWithLocation = events[i];
      if (eventWithLocation.coordinates == null) continue;

      final coords = eventWithLocation.coordinates!;
      final event = eventWithLocation.event;

      markers.add(
        Marker(
          markerId: MarkerId(event.id),
          position: LatLng(coords.latitude, coords.longitude),
          infoWindow: InfoWindow(
            title: event.title,
            snippet: event.venue,
            onTap: () {
              _showEventDetails(event);
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getCategoryColor(event.category),
          ),
          onTap: () {
            _showEventDetails(event);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  BitmapDescriptor _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.concert:
        return BitmapDescriptor.hueRed;
      case EventCategory.party:
        return BitmapDescriptor.hueViolet;
      case EventCategory.conference:
        return BitmapDescriptor.hueBlue;
      case EventCategory.workshop:
        return BitmapDescriptor.hueGreen;
      case EventCategory.festival:
        return BitmapDescriptor.hueOrange;
      case EventCategory.sports:
        return BitmapDescriptor.hueYellow;
      case EventCategory.theater:
        return BitmapDescriptor.hueMagenta;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final currentLocation = _currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (currentLocation != null) {
            // Filter events by location if we have current position
            final nearbyEvents = ref.read(eventsProvider.notifier).getEventsNearby(
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude,
              radiusKm: _searchRadius,
            );
            
            return _buildContent(nearbyEvents.isEmpty ? events : nearbyEvents);
          }
          return _buildContent(events);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppConstants.errorColor),
              const SizedBox(height: 16),
              Text('Error loading events: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(eventsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<EventWithLocation> events) {
    if (_isMapView) {
      return _buildMapView(events);
    } else {
      return _buildListView(events);
    }
  }

  Widget _buildMapView(List<EventWithLocation> events) {
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(37.7749, -122.4194); // Default to San Francisco

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 12.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
            _updateMarkers();
          },
          onCameraMove: (position) {
            // Could update search radius based on zoom level
          },
        ),
        // Search radius control
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search Radius: ${_searchRadius.toStringAsFixed(0)} km',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: _searchRadius,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    label: '${_searchRadius.toStringAsFixed(0)} km',
                    onChanged: (value) {
                      setState(() {
                        _searchRadius = value;
                      });
                      if (_currentPosition != null) {
                        _updateMarkers();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // Events count badge
        Positioned(
          bottom: 16,
          left: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${events.length} events found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<EventWithLocation> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppConstants.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new events',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final eventWithLocation = events[index];
        final event = eventWithLocation.event;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showEventDetails(event),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image or icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: event.imageUri != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event.imageUri!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildEventIcon(event.category),
                            ),
                          )
                        : _buildEventIcon(event.category),
                  ),
                  const SizedBox(width: 16),
                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.venue,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppConstants.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(event.startTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppConstants.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getCategoryName(event.category),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              '\$${event.ticketPriceInDollars.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventIcon(EventCategory category) {
    IconData icon;
    switch (category) {
      case EventCategory.concert:
        icon = Icons.music_note;
        break;
      case EventCategory.party:
        icon = Icons.celebration;
        break;
      case EventCategory.conference:
        icon = Icons.business;
        break;
      case EventCategory.workshop:
        icon = Icons.school;
        break;
      case EventCategory.festival:
        icon = Icons.festival;
        break;
      case EventCategory.sports:
        icon = Icons.sports_soccer;
        break;
      case EventCategory.theater:
        icon = Icons.theater_comedy;
        break;
      default:
        icon = Icons.event;
    }

    return Icon(
      icon,
      size: 40,
      color: AppConstants.primaryColor,
    );
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.concert:
        return 'Concert';
      case EventCategory.party:
        return 'Party';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.festival:
        return 'Festival';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.theater:
        return 'Theater';
      default:
        return 'Other';
    }
  }
}

/// Event details bottom sheet
class _EventDetailsSheet extends StatelessWidget {
  final Event event;

  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Event title
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Venue and location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event.venue}, ${event.location}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date and time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(event.startTime),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Ticket info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '\$${event.ticketPriceInDollars.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tickets',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${event.ticketsRemaining} remaining',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to ticket purchase
                      Navigator.pop(context);
                      // TODO: Navigate to ticket purchase screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Buy Tickets'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

