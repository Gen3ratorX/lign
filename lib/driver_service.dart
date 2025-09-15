// services/driver_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_model.dart';
import 'trip_model.dart';
import 'location_service.dart';
import 'dart:async';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();

  // Get current driver profile
  Future<Driver?> getCurrentDriver() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('drivers').doc(user.uid).get();
      if (doc.exists) {
        return Driver.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting driver: $e');
    }
    return null;
  }

  // Stream current driver data
  Stream<Driver?> getCurrentDriverStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('drivers')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? Driver.fromFirestore(doc) : null);
  }

  // Check if driver profile exists
  Future<bool> hasDriverProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('drivers').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking driver profile: $e');
      return false;
    }
  }

  // Get trips assigned to driver's routes for today
  Stream<List<Trip>> getTodaysTrips() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('drivers')
        .doc(user.uid)
        .snapshots()
        .asyncExpand((driverDoc) {
      if (!driverDoc.exists) return Stream.value([]);

      final driverData = driverDoc.data() as Map<String, dynamic>;
      final assignedRoutes = List<String>.from(driverData['assignedRoutes'] ?? []);

      if (assignedRoutes.isEmpty) return Stream.value([]);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return _firestore
          .collection('trips')
          .where('routeId', whereIn: assignedRoutes)
          .where('status', whereIn: ['booked', 'active', 'ongoing'])
          .where('departureTime', isGreaterThanOrEqualTo: startOfDay)
          .where('departureTime', isLessThanOrEqualTo: endOfDay)
          .orderBy('departureTime')
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
    });
  }

  // Get next trip for driver
  Future<Map<String, dynamic>?> getNextTrip() async {
    final driver = await getCurrentDriver();
    if (driver == null || driver.assignedRoutes.isEmpty) return null;

    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('trips')
          .where('routeId', whereIn: driver.assignedRoutes)
          .where('status', isEqualTo: 'booked')
          .where('departureTime', isGreaterThan: now)
          .orderBy('departureTime')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final trip = Trip.fromFirestore(snapshot.docs.first);

        // Count total passengers for this route and departure time
        final passengerCount = await _getPassengerCountForTrip(trip);

        return {
          'tripId': trip.id,
          'route': '${trip.from} → ${trip.to}',
          'departureTime': trip.departureTime,
          'passengerCount': passengerCount,
          'capacity': driver.capacity,
          'routeId': trip.routeId,
          'from': trip.from,
          'to': trip.to,
        };
      }
    } catch (e) {
      print('Error getting next trip: $e');
    }

    return null;
  }

  // Get passenger count for a specific route and time
  Future<int> _getPassengerCountForTrip(Trip trip) async {
    try {
      final startOfHour = DateTime(
        trip.departureTime.year,
        trip.departureTime.month,
        trip.departureTime.day,
        trip.departureTime.hour,
      );
      final endOfHour = startOfHour.add(const Duration(hours: 1));

      final passengerSnapshot = await _firestore
          .collection('trips')
          .where('routeId', isEqualTo: trip.routeId)
          .where('status', whereIn: ['booked', 'active'])
          .where('departureTime', isGreaterThanOrEqualTo: startOfHour)
          .where('departureTime', isLessThan: endOfHour)
          .get();

      return passengerSnapshot.docs.length;
    } catch (e) {
      print('Error getting passenger count: $e');
      return 0;
    }
  }

  // Start shift / Go on duty with location tracking
  Future<void> startShift() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnDuty': true,
        'shiftStartTime': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });

      // Start location tracking automatically when going on duty
      await _locationService.startDriverLocationTracking();

      print('Shift started with location tracking');
    } catch (e) {
      throw Exception('Failed to start shift: $e');
    }
  }

  // End shift / Go off duty and stop location tracking
  Future<void> endShift() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Stop location tracking first
      await _locationService.stopDriverLocationTracking();

      await _firestore.collection('drivers').doc(user.uid).update({
        'isOnDuty': false,
        'currentRoute': null,
        'shiftStartTime': null,
        'currentLatitude': null,
        'currentLongitude': null,
        'lastUpdated': Timestamp.now(),
      });

      print('Shift ended and location tracking stopped');
    } catch (e) {
      throw Exception('Failed to end shift: $e');
    }
  }

  // Start a specific route with tracking
  Future<void> startRoute(String routeId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      // Update driver current route
      final driverRef = _firestore.collection('drivers').doc(user.uid);
      batch.update(driverRef, {
        'currentRoute': routeId,
        'lastUpdated': Timestamp.now(),
      });

      // Update all booked trips to active for this route in the next hour
      final now = DateTime.now();
      final nextHour = now.add(const Duration(hours: 1));

      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('routeId', isEqualTo: routeId)
          .where('status', isEqualTo: 'booked')
          .where('departureTime', isGreaterThanOrEqualTo: now)
          .where('departureTime', isLessThanOrEqualTo: nextHour)
          .get();

      for (var doc in tripsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'active',
          'tripStartTime': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }

      await batch.commit();

      // Ensure location tracking is active
      if (!_locationService.isDriverTrackingActive) {
        await _locationService.startDriverLocationTracking();
      }

      // Send notifications to passengers
      await _sendTripStartNotifications(routeId);

      print('Route started with real-time tracking');

    } catch (e) {
      throw Exception('Failed to start route: $e');
    }
  }

  // Complete a route
  Future<void> completeRoute(String routeId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      // Update driver
      final driverRef = _firestore.collection('drivers').doc(user.uid);
      batch.update(driverRef, {
        'currentRoute': null,
        'lastUpdated': Timestamp.now(),
      });

      // Complete all active trips for this route
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('routeId', isEqualTo: routeId)
          .where('status', whereIn: ['active', 'ongoing'])
          .get();

      for (var doc in tripsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'completed',
          'completedAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
          // Clear driver location data from completed trips
          'driverLatitude': null,
          'driverLongitude': null,
          'lastDriverUpdate': null,
        });
      }

      await batch.commit();

      print('Route completed');
    } catch (e) {
      throw Exception('Failed to complete route: $e');
    }
  }

  // Get active passengers for current route
  Future<List<Trip>> getActivePassengers() async {
    final driver = await getCurrentDriver();
    if (driver == null || driver.currentRoute == null) return [];

    try {
      final snapshot = await _firestore
          .collection('trips')
          .where('routeId', isEqualTo: driver.currentRoute)
          .where('status', whereIn: ['active', 'ongoing'])
          .orderBy('departureTime')
          .get();

      return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting active passengers: $e');
      return [];
    }
  }

  // Send trip start notifications
  Future<void> _sendTripStartNotifications(String routeId) async {
    try {
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('routeId', isEqualTo: routeId)
          .where('status', isEqualTo: 'active')
          .get();

      final batch = _firestore.batch();

      for (var doc in tripsSnapshot.docs) {
        final tripData = doc.data();
        final notificationRef = _firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': tripData['userId'],
          'tripId': doc.id,
          'title': 'Trip Started',
          'message': 'Your driver is now on the way to your pickup location',
          'type': 'trip_started',
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  // Get driver's current location
  Future<Map<String, double>?> getCurrentDriverLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    return null;
  }

  // Check if driver is near a passenger pickup location
  Future<bool> isNearPassengerPickup(String tripId) async {
    return await _locationService.isDriverNearPickup(tripId);
  }

  // Create or update driver profile
  Future<void> createDriverProfile({
    required String name,
    required String busNumber,
    required String licenseNumber,
    required String phoneNumber,
    required int capacity,
    List<String>? assignedRoutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('drivers').doc(user.uid).set({
        'name': name,
        'busNumber': busNumber,
        'licenseNumber': licenseNumber,
        'phoneNumber': phoneNumber,
        'capacity': capacity,
        'assignedRoutes': assignedRoutes ?? [],
        'isOnDuty': false,
        'rating': 4.5,
        'currentLatitude': null,
        'currentLongitude': null,
        'currentRoute': null,
        'shiftStartTime': null,
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });

      print('Driver profile created successfully');
    } catch (e) {
      throw Exception('Failed to create driver profile: $e');
    }
  }

  // Update driver profile
  Future<void> updateDriverProfile({
    String? name,
    String? busNumber,
    String? licenseNumber,
    String? phoneNumber,
    int? capacity,
    List<String>? assignedRoutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updates = <String, dynamic>{
        'lastUpdated': Timestamp.now(),
      };

      if (name != null) updates['name'] = name;
      if (busNumber != null) updates['busNumber'] = busNumber;
      if (licenseNumber != null) updates['licenseNumber'] = licenseNumber;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (capacity != null) updates['capacity'] = capacity;
      if (assignedRoutes != null) updates['assignedRoutes'] = assignedRoutes;

      await _firestore.collection('drivers').doc(user.uid).update(updates);

      print('Driver profile updated successfully');
    } catch (e) {
      throw Exception('Failed to update driver profile: $e');
    }
  }

  // Get real-time location service instance
  LocationService get locationService => _locationService;

  void dispose() {
    _locationService.dispose();
  }
}