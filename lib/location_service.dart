// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  loc.Location location = loc.Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _driverLocationSubscription;
  Timer? _locationBackupTimer;
  bool _isDriverTracking = false;

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }

  // Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          longitude: locations[0].longitude,
          latitude: locations[0].latitude,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
    return null;
  }

  // Get location stream
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Start driver location tracking
  Future<void> startDriverLocationTracking() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    if (_isDriverTracking) {
      print('Driver tracking already active');
      return;
    }

    _isDriverTracking = true;
    print('Starting driver location tracking...');

    try {
      // Start continuous location updates
      _driverLocationSubscription = getLocationStream().listen(
            (Position position) {
          _updateDriverLocationInFirebase(position);
        },
        onError: (error) {
          print('Location stream error: $error');
          _handleLocationError(error);
        },
      );

      // Backup timer for location updates every 30 seconds
      _locationBackupTimer = Timer.periodic(
        const Duration(seconds: 30),
            (timer) async {
          if (_isDriverTracking) {
            final position = await getCurrentLocation();
            if (position != null) {
              await _updateDriverLocationInFirebase(position);
            }
          }
        },
      );

      print('Driver location tracking started successfully');
    } catch (e) {
      _isDriverTracking = false;
      print('Error starting driver location tracking: $e');
      throw Exception('Failed to start location tracking: $e');
    }
  }

  // Update driver location in Firebase
  Future<void> _updateDriverLocationInFirebase(Position position) async {
    final user = _auth.currentUser;
    if (user == null || !_isDriverTracking) return;

    try {
      final batch = _firestore.batch();

      // Update driver document
      final driverRef = _firestore.collection('drivers').doc(user.uid);
      batch.update(driverRef, {
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        'lastLocationUpdate': Timestamp.now(),
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
      });

      // Get driver's current route to update related trips
      final driverDoc = await driverRef.get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
        final currentRoute = driverData['currentRoute'];

        if (currentRoute != null) {
          // Update all active trips for this route
          final tripsQuery = await _firestore
              .collection('trips')
              .where('routeId', isEqualTo: currentRoute)
              .where('status', whereIn: ['active', 'ongoing'])
              .get();

          for (var tripDoc in tripsQuery.docs) {
            final tripData = tripDoc.data();
            final eta = await _calculateETAToDestination(
              position.latitude,
              position.longitude,
              tripData,
            );

            batch.update(tripDoc.reference, {
              'driverLatitude': position.latitude,
              'driverLongitude': position.longitude,
              'driverSpeed': position.speed,
              'driverHeading': position.heading,
              'driverAccuracy': position.accuracy,
              'lastDriverUpdate': Timestamp.now(),
              'estimatedArrivalMinutes': eta,
            });
          }
        }
      }

      await batch.commit();
      print('Driver location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  // Calculate ETA to destination
  Future<int> _calculateETAToDestination(
      double driverLat,
      double driverLng,
      Map<String, dynamic> tripData) async {
    try {
      double? destLat = tripData['destinationLatitude']?.toDouble();
      double? destLng = tripData['destinationLongitude']?.toDouble();

      // If no coordinates, try to get them from destination address
      if (destLat == null || destLng == null) {
        final destination = tripData['to'] as String?;
        if (destination != null) {
          final position = await getCoordinatesFromAddress(destination);
          if (position != null) {
            destLat = position.latitude;
            destLng = position.longitude;
          }
        }
      }

      if (destLat != null && destLng != null) {
        final distanceInMeters = Geolocator.distanceBetween(
            driverLat, driverLng, destLat, destLng);
        final distanceKm = distanceInMeters / 1000;

        // Use dynamic speed calculation based on current speed
        final currentSpeed = tripData['driverSpeed']?.toDouble() ?? 0.0;
        final averageSpeedKmh = currentSpeed > 0
            ? (currentSpeed * 3.6) // Convert m/s to km/h
            : 30.0; // Default speed

        final etaMinutes = (distanceKm / averageSpeedKmh * 60).round();
        return etaMinutes.clamp(1, 120); // Between 1 and 120 minutes
      }
    } catch (e) {
      print('Error calculating ETA: $e');
    }
    return 15; // Default ETA
  }

  // Handle location errors
  void _handleLocationError(dynamic error) {
    print('Location error: $error');
    // Could implement retry logic or fallback mechanisms here
  }

  // Stop driver location tracking
  Future<void> stopDriverLocationTracking() async {
    print('Stopping driver location tracking...');

    _isDriverTracking = false;

    // Cancel subscriptions
    await _driverLocationSubscription?.cancel();
    _locationBackupTimer?.cancel();

    _driverLocationSubscription = null;
    _locationBackupTimer = null;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Clear location data from driver document
        await _firestore.collection('drivers').doc(user.uid).update({
          'currentLatitude': null,
          'currentLongitude': null,
          'lastLocationUpdate': null,
          'speed': null,
          'heading': null,
          'accuracy': null,
        });

        // Clear location data from active trips
        final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
        if (driverDoc.exists) {
          final driverData = driverDoc.data() as Map<String, dynamic>;
          final currentRoute = driverData['currentRoute'];

          if (currentRoute != null) {
            final tripsQuery = await _firestore
                .collection('trips')
                .where('routeId', isEqualTo: currentRoute)
                .where('status', whereIn: ['active', 'ongoing'])
                .get();

            final batch = _firestore.batch();
            for (var tripDoc in tripsQuery.docs) {
              batch.update(tripDoc.reference, {
                'driverLatitude': null,
                'driverLongitude': null,
                'driverSpeed': null,
                'driverHeading': null,
                'driverAccuracy': null,
                'lastDriverUpdate': null,
              });
            }
            await batch.commit();
          }
        }

        print('Driver location tracking stopped and data cleared');
      } catch (e) {
        print('Error clearing driver location: $e');
      }
    }
  }

  // Check if driver tracking is active
  bool get isDriverTrackingActive => _isDriverTracking;

  // Get driver location for a specific trip (stream)
  Stream<Map<String, dynamic>?> getDriverLocationForTrip(String routeId) {
    return _firestore
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .where('status', whereIn: ['active', 'ongoing'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final driverLat = data['driverLatitude']?.toDouble();
      final driverLng = data['driverLongitude']?.toDouble();

      if (driverLat != null && driverLng != null) {
        return {
          'latitude': driverLat,
          'longitude': driverLng,
          'speed': data['driverSpeed']?.toDouble() ?? 0.0,
          'heading': data['driverHeading']?.toDouble() ?? 0.0,
          'accuracy': data['driverAccuracy']?.toDouble() ?? 0.0,
          'lastUpdate': data['lastDriverUpdate'],
          'eta': data['estimatedArrivalMinutes'] ?? 15,
        };
      }
      return null;
    });
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Check if driver is near pickup location
  Future<bool> isDriverNearPickup(String tripId, {double radiusMeters = 100}) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final tripData = tripDoc.data() as Map<String, dynamic>;

      final driverLat = tripData['driverLatitude']?.toDouble();
      final driverLng = tripData['driverLongitude']?.toDouble();
      final pickupLat = tripData['pickupLatitude']?.toDouble();
      final pickupLng = tripData['pickupLongitude']?.toDouble();

      if (driverLat != null && driverLng != null && pickupLat != null && pickupLng != null) {
        final distance = calculateDistance(driverLat, driverLng, pickupLat, pickupLng);
        return distance <= radiusMeters;
      }
      return false;
    } catch (e) {
      print('Error checking driver proximity: $e');
      return false;
    }
  }

  // Get current location with retry mechanism
  Future<Position?> getCurrentLocationWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final position = await getCurrentLocation();
        if (position != null) return position;

        // Wait before retry
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (i + 1) * 2));
        }
      } catch (e) {
        print('Location attempt ${i + 1} failed: $e');
      }
    }
    return null;
  }

  // Dispose resources
  void dispose() {
    stopDriverLocationTracking();
  }
}