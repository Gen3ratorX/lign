import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class Trip {
  final String id;
  final String userId;
  final String routeId;
  final String from;
  final String to;
  final String busNumber;
  final String driverName;
  final String status;
  final DateTime departureTime;
  final DateTime bookingTime;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? nextStop;
  final int? estimatedArrivalMinutes;

  Trip({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.from,
    required this.to,
    required this.busNumber,
    required this.driverName,
    required this.status,
    required this.departureTime,
    required this.bookingTime,
    this.currentLatitude,
    this.currentLongitude,
    this.nextStop,
    this.estimatedArrivalMinutes,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      routeId: data['routeId'] ?? '',
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      busNumber: data['busNumber'] ?? '',
      driverName: data['driverName'] ?? '',
      status: data['status'] ?? 'booked',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      currentLatitude: data['currentLatitude']?.toDouble(),
      currentLongitude: data['currentLongitude']?.toDouble(),
      nextStop: data['nextStop'],
      estimatedArrivalMinutes: data['estimatedArrivalMinutes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routeId': routeId,
      'from': from,
      'to': to,
      'busNumber': busNumber,
      'driverName': driverName,
      'status': status,
      'departureTime': Timestamp.fromDate(departureTime),
      'bookingTime': Timestamp.fromDate(bookingTime),
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'nextStop': nextStop,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
    };
  }
}

// models/route_model.dart
class BusRoute {
  final String id;
  final String from;
  final String to;
  final String busNumber;
  final String driverName;
  final DateTime departureTime;
  final int availableSeats;
  final double price;
  final String status;
  final List<String> stops;
  final double estimatedDurationMinutes;

  BusRoute({
    required this.id,
    required this.from,
    required this.to,
    required this.busNumber,
    required this.driverName,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
    required this.status,
    required this.stops,
    required this.estimatedDurationMinutes,
  });

  factory BusRoute.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BusRoute(
      id: doc.id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      busNumber: data['busNumber'] ?? '',
      driverName: data['driverName'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      availableSeats: data['availableSeats'] ?? 0,
      price: data['price']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
      stops: List<String>.from(data['stops'] ?? []),
      estimatedDurationMinutes: data['estimatedDurationMinutes']?.toDouble() ?? 60.0,
    );
  }
}


class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's active trips
  Stream<List<Trip>> getUserActiveTrips() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['booked', 'active', 'ongoing'])
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
  }

  // Get user's trip history
  Stream<List<Trip>> getUserTripHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
  }

  // Book a new trip
  Future<String> bookTrip({
    required String routeId,
    required String from,
    required String to,
    required String busNumber,
    required String driverName,
    required DateTime departureTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final tripData = {
      'userId': user.uid,
      'routeId': routeId,
      'from': from,
      'to': to,
      'busNumber': busNumber,
      'driverName': driverName,
      'status': 'booked',
      'departureTime': Timestamp.fromDate(departureTime),
      'bookingTime': Timestamp.now(),
    };

    final docRef = await _firestore.collection('trips').add(tripData);
    return docRef.id;
  }

  // Update trip status
  Future<void> updateTripStatus(String tripId, String status) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': status,
      'lastUpdated': Timestamp.now(),
    });
  }

  // Update trip location (for real-time tracking)
  Future<void> updateTripLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    String? nextStop,
    int? estimatedArrivalMinutes,
  }) async {
    await _firestore.collection('trips').doc(tripId).update({
      'currentLatitude': latitude,
      'currentLongitude': longitude,
      'nextStop': nextStop,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'lastUpdated': Timestamp.now(),
    });
  }

  // Cancel trip
  Future<void> cancelTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.now(),
    });
  }
}

// services/route_service.dart
class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available routes
  Future<List<BusRoute>> getAvailableRoutes({String? from, String? to}) async {
    Query query = _firestore.collection('routes').where('status', isEqualTo: 'active');

    if (from != null) {
      query = query.where('from', isEqualTo: from);
    }
    if (to != null) {
      query = query.where('to', isEqualTo: to);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => BusRoute.fromFirestore(doc)).toList();
  }

  // Get route by ID
  Future<BusRoute?> getRouteById(String routeId) async {
    final doc = await _firestore.collection('routes').doc(routeId).get();
    if (doc.exists) {
      return BusRoute.fromFirestore(doc);
    }
    return null;
  }

  // Search routes by destination
  Future<List<BusRoute>> searchRoutes(String searchTerm) async {
    final fromSnapshot = await _firestore
        .collection('routes')
        .where('from', isGreaterThanOrEqualTo: searchTerm)
        .where('from', isLessThan: searchTerm + '\uf8ff')
        .where('status', isEqualTo: 'active')
        .get();

    final toSnapshot = await _firestore
        .collection('routes')
        .where('to', isGreaterThanOrEqualTo: searchTerm)
        .where('to', isLessThan: searchTerm + '\uf8ff')
        .where('status', isEqualTo: 'active')
        .get();

    final routes = <BusRoute>[];
    final routeIds = <String>{};

    for (final doc in [...fromSnapshot.docs, ...toSnapshot.docs]) {
      if (!routeIds.contains(doc.id)) {
        routes.add(BusRoute.fromFirestore(doc));
        routeIds.add(doc.id);
      }
    }

    return routes;
  }

  // Get popular destinations
  Future<List<String>> getPopularDestinations() async {
    final snapshot = await _firestore
        .collection('routes')
        .where('status', isEqualTo: 'active')
        .orderBy('popularityScore', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()['to'] as String).toSet().toList();
  }
}

// services/notification_service.dart
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send trip notification
  Future<void> sendTripNotification({
    required String userId,
    required String tripId,
    required String title,
    required String message,
    String type = 'trip_update',
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'tripId': tripId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.now(),
    });
  }
}

class LocationUtils {
  // Calculate distance between two points
  static double calculateDistance(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    const double earthRadius = 6371; // km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Estimate arrival time based on distance and speed
  static int estimateArrivalTime(double distanceKm, {double averageSpeedKmh = 30}) {
    return (distanceKm / averageSpeedKmh * 60).round(); // minutes
  }

  // Format address for display
  static String formatAddress(String address) {
    return address.split(',').first.trim();
  }
}

// constants/app_constants.dart
class AppConstants {
  static const String APP_NAME = 'RideFlow';

  // Trip Status
  static const String TRIP_BOOKED = 'booked';
  static const String TRIP_ACTIVE = 'active';
  static const String TRIP_ONGOING = 'ongoing';
  static const String TRIP_COMPLETED = 'completed';
  static const String TRIP_CANCELLED = 'cancelled';

  // Route Status
  static const String ROUTE_ACTIVE = 'active';
  static const String ROUTE_INACTIVE = 'inactive';
  static const String ROUTE_SUSPENDED = 'suspended';

  // Notification Types
  static const String NOTIFICATION_TRIP_UPDATE = 'trip_update';
  static const String NOTIFICATION_DRIVER_ARRIVED = 'driver_arrived';
  static const String NOTIFICATION_TRIP_STARTED = 'trip_started';
  static const String NOTIFICATION_TRIP_CANCELLED = 'trip_cancelled';

  // Colors
  static const Map<String, dynamic> APP_COLORS = {
    'primary': 0xFF667eea,
    'secondary': 0xFF764ba2,
    'success': 0xFF4CAF50,
    'warning': 0xFFFF9800,
    'error': 0xFFF44336,
    'info': 0xFF2196F3,
  };
}