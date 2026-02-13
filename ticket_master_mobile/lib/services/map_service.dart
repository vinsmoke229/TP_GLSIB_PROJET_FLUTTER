import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// ============================================================================
/// MAP SERVICE - Real GPS Navigation Integration (Android 11+ Compatible)
/// ============================================================================
/// Features:
/// - Open Google Maps with directions
/// - Get user's current location
/// - Calculate distance to destination
/// - Launch external maps app (FORCED external mode for Android 11+)
/// ============================================================================

class MapService {
  /// Open Google Maps with directions from current location to destination
  /// Uses Google Maps URL scheme for cross-platform compatibility
  /// CRITICAL: Uses LaunchMode.externalApplication for Android 11+
  Future<void> openMapsItinerary({
    required double destLat,
    required double destLon,
    String? destName,
  }) async {
    try {

// Get user's current location
      Position? userPosition;
      try {
        userPosition = await _getCurrentLocation();
        
      } catch (e) {
        
        // Continue without user location (Google Maps will use device location)
      }
      
      // Build Google Maps URL
      String mapsUrl;
      
      if (userPosition != null) {
        // With origin (user's current location)
        mapsUrl = 'https://www.google.com/maps/dir/?api=1'
            '&origin=${userPosition.latitude},${userPosition.longitude}'
            '&destination=$destLat,$destLon'
            '&travelmode=driving';
      } else {
        // Without origin (Google Maps will use device location)
        mapsUrl = 'https://www.google.com/maps/dir/?api=1'
            '&destination=$destLat,$destLon'
            '&travelmode=driving';
      }

// Launch URL with FORCED external application mode
      final uri = Uri.parse(mapsUrl);
      
      // CRITICAL: Use externalApplication mode to force Android to open Google Maps
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        
      } else {
        
        throw Exception('Could not open maps application');
      }
    } catch (e) {
      
      throw Exception('Failed to open maps: $e');
    }
  }
  
  /// Open Google Maps to view a specific location
  /// Shows the location on the map without directions
  /// CRITICAL: Uses LaunchMode.externalApplication for Android 11+
  Future<void> openMapsLocation({
    required double lat,
    required double lon,
    String? locationName,
  }) async {
    try {

// Build Google Maps URL for viewing location
      String mapsUrl = 'https://www.google.com/maps/search/?api=1'
          '&query=$lat,$lon';
      
      if (locationName != null && locationName.isNotEmpty) {
        // Add location name as query
        final encodedName = Uri.encodeComponent(locationName);
        mapsUrl = 'https://www.google.com/maps/search/?api=1'
            '&query=$encodedName';
      }

// Launch URL with FORCED external application mode
      final uri = Uri.parse(mapsUrl);
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        
      } else {
        
        throw Exception('Could not open maps application');
      }
    } catch (e) {
      
      throw Exception('Failed to open maps: $e');
    }
  }
  
  /// Get user's current location
  Future<Position> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    
    // Get current position with high accuracy
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
  
  /// Calculate distance between two points in kilometers
  Future<double> calculateDistance({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    try {
      final distanceInMeters = Geolocator.distanceBetween(
        startLat,
        startLon,
        endLat,
        endLon,
      );
      
      final distanceInKm = distanceInMeters / 1000;

return distanceInKm;
    } catch (e) {
      
      return 0.0;
    }
  }
  
  /// Get distance from user's current location to destination
  Future<double?> getDistanceToDestination({
    required double destLat,
    required double destLon,
  }) async {
    try {
      final userPosition = await _getCurrentLocation();
      
      return await calculateDistance(
        startLat: userPosition.latitude,
        startLon: userPosition.longitude,
        endLat: destLat,
        endLon: destLon,
      );
    } catch (e) {
      
      return null;
    }
  }
}
