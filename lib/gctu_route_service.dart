// services/gctu_route_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class GCTURouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active routes to GCTU
  Future<List<Map<String, dynamic>>> getToUniversityRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('direction', isEqualTo: 'to_university')
          .where('isActive', isEqualTo: true)
          .orderBy('from')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting to university routes: $e');
      return [];
    }
  }

  // Get all active routes from GCTU
  Future<List<Map<String, dynamic>>> getFromUniversityRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('direction', isEqualTo: 'from_university')
          .where('isActive', isEqualTo: true)
          .orderBy('to')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting from university routes: $e');
      return [];
    }
  }

  // Get routes by origin location
  Future<List<Map<String, dynamic>>> getRoutesByOrigin(String origin) async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('from', isEqualTo: origin)
          .where('isActive', isEqualTo: true)
          .orderBy('departureTime')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting routes by origin: $e');
      return [];
    }
  }

  // Get routes by destination
  Future<List<Map<String, dynamic>>> getRoutesByDestination(String destination) async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('to', isEqualTo: destination)
          .where('isActive', isEqualTo: true)
          .orderBy('departureTime')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting routes by destination: $e');
      return [];
    }
  }

  // Search routes by origin or destination
  Future<List<Map<String, dynamic>>> searchRoutes(String searchTerm) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();

      // Get all routes and filter locally for better search capability
      final snapshot = await _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.where((doc) {
        final data = doc.data();
        final from = data['from'].toString().toLowerCase();
        final to = data['to'].toString().toLowerCase();
        final routeCode = data['routeCode'].toString().toLowerCase();

        return from.contains(searchTermLower) ||
            to.contains(searchTermLower) ||
            routeCode.contains(searchTermLower);
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error searching routes: $e');
      return [];
    }
  }

  // Get specific route by ID
  Future<Map<String, dynamic>?> getRouteById(String routeId) async {
    try {
      final doc = await _firestore.collection('routes').doc(routeId).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting route by ID: $e');
      return null;
    }
  }

  // Get pickup points for a route
  Future<List<Map<String, dynamic>>> getPickupPoints(String routeId) async {
    try {
      final route = await getRouteById(routeId);
      if (route == null) return [];

      final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
      return stops.where((stop) => stop['isPickupPoint'] == true).toList();
    } catch (e) {
      print('Error getting pickup points: $e');
      return [];
    }
  }

  // Get all stops for a route
  Future<List<Map<String, dynamic>>> getAllStops(String routeId) async {
    try {
      final route = await getRouteById(routeId);
      if (route == null) return [];

      final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
      stops.sort((a, b) => a['order'].compareTo(b['order']));
      return stops;
    } catch (e) {
      print('Error getting all stops: $e');
      return [];
    }
  }

  // Get available schedules for a route
  Future<List<Map<String, dynamic>>> getRouteSchedules(String routeId) async {
    try {
      final route = await getRouteById(routeId);
      if (route == null) return [];

      return List<Map<String, dynamic>>.from(route['schedules'] ?? []);
    } catch (e) {
      print('Error getting route schedules: $e');
      return [];
    }
  }

  // Find nearest pickup point to user location
  Future<Map<String, dynamic>?> findNearestPickupPoint(
      String routeId,
      double userLat,
      double userLng
      ) async {
    try {
      final pickupPoints = await getPickupPoints(routeId);
      if (pickupPoints.isEmpty) return null;

      Map<String, dynamic>? nearest;
      double minDistance = double.infinity;

      for (var point in pickupPoints) {
        final distance = _calculateDistance(
            userLat,
            userLng,
            point['latitude'],
            point['longitude']
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
          nearest['distanceKm'] = distance;
        }
      }

      return nearest;
    } catch (e) {
      print('Error finding nearest pickup point: $e');
      return null;
    }
  }

  // Get routes available at specific time
  Future<List<Map<String, dynamic>>> getRoutesAtTime(String time, {String? origin}) async {
    try {
      Query query = _firestore
          .collection('routes')
          .where('isActive', isEqualTo: true);

      if (origin != null) {
        query = query.where('from', isEqualTo: origin);
      }

      final snapshot = await query.get();

      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final schedules = List<Map<String, dynamic>>.from(data['schedules'] ?? []);

        return schedules.any((schedule) =>
        schedule['departureTime'] == time
        );
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting routes at time: $e');
      return [];
    }
  }

  // Get popular origins (most frequently searched)
  Future<List<String>> getPopularOrigins() async {
    return ['Kasoa', 'Teshie', 'Tema', 'Nsawam'];
  }

  // Book a trip on a specific route
  Future<String> bookTrip({
    required String routeId,
    required String userId,
    required String pickupPointName,
    required String departureTime,
    required DateTime travelDate,
  }) async {
    try {
      final route = await getRouteById(routeId);
      if (route == null) throw Exception('Route not found');

      // Find the pickup point
      final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
      final pickupPoint = stops.firstWhere(
            (stop) => stop['name'] == pickupPointName && stop['isPickupPoint'] == true,
        orElse: () => throw Exception('Pickup point not found'),
      );

      // Create trip document
      final tripData = {
        'userId': userId,
        'routeId': routeId,
        'routeCode': route['routeCode'],
        'from': route['from'],
        'to': route['to'],
        'pickupPoint': pickupPointName,
        'pickupLatitude': pickupPoint['latitude'],
        'pickupLongitude': pickupPoint['longitude'],
        'departureTime': _parseTimeToDateTime(departureTime, travelDate),
        'estimatedArrival': _parseTimeToDateTime(departureTime, travelDate)
            .add(Duration(minutes: route['estimatedDuration'])),
        'fare': route['fare'],
        'status': 'booked',
        'bookingTime': Timestamp.now(),
        'travelDate': Timestamp.fromDate(travelDate),
        'estimatedDuration': route['estimatedDuration'],
        'distance': route['distance'],
      };

      final docRef = await _firestore.collection('trips').add(tripData);
      return docRef.id;
    } catch (e) {
      print('Error booking trip: $e');
      throw Exception('Failed to book trip: $e');
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Parse time string to DateTime
  DateTime _parseTimeToDateTime(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // Get estimated arrival time for a pickup point
  Duration getEstimatedArrivalTime(Map<String, dynamic> route, String pickupPointName) {
    final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
    final stop = stops.firstWhere(
          (s) => s['name'] == pickupPointName,
      orElse: () => {'estimatedTime': '00:00'},
    );

    final timeStr = stop['estimatedTime'] as String;
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    return Duration(hours: hours, minutes: minutes);
  }

  // Check if route operates on specific day
  bool isRouteAvailableOnDay(Map<String, dynamic> route, DateTime date) {
    final schedules = List<Map<String, dynamic>>.from(route['schedules'] ?? []);
    final dayName = _getDayName(date.weekday);

    return schedules.any((schedule) {
      final daysOfWeek = List<String>.from(schedule['daysOfWeek'] ?? []);
      return daysOfWeek.contains(dayName);
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  // Stream routes (real-time updates)
  Stream<List<Map<String, dynamic>>> streamToUniversityRoutes() {
    return _firestore
        .collection('routes')
        .where('direction', isEqualTo: 'to_university')
        .where('isActive', isEqualTo: true)
        .orderBy('from')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Stream<List<Map<String, dynamic>>> streamFromUniversityRoutes() {
    return _firestore
        .collection('routes')
        .where('direction', isEqualTo: 'from_university')
        .where('isActive', isEqualTo: true)
        .orderBy('to')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }
}