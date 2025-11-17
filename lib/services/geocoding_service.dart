import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// Service for converting location strings to coordinates
class GeocodingService {
  /// Convert a location string (address) to coordinates
  Future<LocationCoordinates?> getCoordinatesFromAddress(String address) async {
    try {
      if (address.isEmpty) return null;
      
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      
      final location = locations.first;
      return LocationCoordinates(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      debugPrint('Error geocoding address "$address": $e');
      return null;
    }
  }

  /// Convert coordinates to address
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      
      final placemark = placemarks.first;
      final address = [
        placemark.street,
        placemark.locality,
        placemark.administrativeArea,
        placemark.country,
      ].where((element) => element != null && element!.isNotEmpty).join(', ');
      
      return address.isEmpty ? null : address;
    } catch (e) {
      debugPrint('Error reverse geocoding coordinates: $e');
      return null;
    }
  }

  /// Batch geocode multiple addresses
  Future<Map<String, LocationCoordinates?>> batchGeocode(List<String> addresses) async {
    final results = <String, LocationCoordinates?>{};
    
    for (final address in addresses) {
      results[address] = await getCoordinatesFromAddress(address);
    }
    
    return results;
  }
}

/// Location coordinates model
class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'LocationCoordinates(lat: $latitude, lng: $longitude)';
}

