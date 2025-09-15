// data/gctu_routes_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class GCTURoutesData {
  // Ghana Communication Technology University coordinates
  static const Map<String, double> gctuCoordinates = {
    'latitude': 5.6037,
    'longitude': -0.1870,
  };

  // Route data for all major origins to GCTU
  static List<Map<String, dynamic>> getAllRoutes() {
    return [
      // KASOA TO GCTU ROUTE
      {
        'id': 'kasoa_to_gctu_morning',
        'routeCode': 'KAS-GCTU-M',
        'from': 'Kasoa',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Kasoa Toll Booth',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 45, // minutes
        'distance': 28.5, // kilometers
        'fare': 8.00, // GHS
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '06:00',
            'arrivalTime': '06:45',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '07:00',
            'arrivalTime': '07:45',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '08:00',
            'arrivalTime': '08:45',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Kasoa Toll Booth',
            'latitude': 5.5306,
            'longitude': -0.4167,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Kasoa Market',
            'latitude': 5.5289,
            'longitude': -0.4123,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Bawjiase Junction',
            'latitude': 5.5456,
            'longitude': -0.3894,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Ofaakor',
            'latitude': 5.5667,
            'longitude': -0.3556,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Mallam Junction',
            'latitude': 5.5889,
            'longitude': -0.3000,
            'order': 4,
            'isPickupPoint': true,
            'estimatedTime': '00:25',
          },
          {
            'name': 'Dansoman',
            'latitude': 5.5944,
            'longitude': -0.2667,
            'order': 5,
            'isPickupPoint': true,
            'estimatedTime': '00:30',
          },
          {
            'name': 'Kaneshie',
            'latitude': 5.5833,
            'longitude': -0.2333,
            'order': 6,
            'isPickupPoint': true,
            'estimatedTime': '00:35',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 7,
            'isPickupPoint': false,
            'estimatedTime': '00:45',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO KASOA ROUTE (RETURN)
      {
        'id': 'gctu_to_kasoa_evening',
        'routeCode': 'GCTU-KAS-E',
        'from': 'GCTU Campus',
        'to': 'Kasoa',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Kasoa Toll Booth',
        'estimatedDuration': 45,
        'distance': 28.5,
        'fare': 8.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:00',
            'arrivalTime': '16:45',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '17:30',
            'arrivalTime': '18:15',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Kaneshie',
            'latitude': 5.5833,
            'longitude': -0.2333,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Dansoman',
            'latitude': 5.5944,
            'longitude': -0.2667,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Mallam Junction',
            'latitude': 5.5889,
            'longitude': -0.3000,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:20',
          },
          {
            'name': 'Ofaakor',
            'latitude': 5.5667,
            'longitude': -0.3556,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:30',
          },
          {
            'name': 'Bawjiase Junction',
            'latitude': 5.5456,
            'longitude': -0.3894,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:35',
          },
          {
            'name': 'Kasoa Market',
            'latitude': 5.5289,
            'longitude': -0.4123,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '00:40',
          },
          {
            'name': 'Kasoa Toll Booth',
            'latitude': 5.5306,
            'longitude': -0.4167,
            'order': 7,
            'isPickupPoint': false,
            'estimatedTime': '00:45',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // TESHIE TO GCTU ROUTE
      {
        'id': 'teshie_to_gctu_morning',
        'routeCode': 'TSH-GCTU-M',
        'from': 'Teshie',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Teshie Nungua Estates',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 35,
        'distance': 18.5,
        'fare': 6.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '06:30',
            'arrivalTime': '07:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '07:30',
            'arrivalTime': '08:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Teshie Nungua Estates',
            'latitude': 5.5958,
            'longitude': -0.1014,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Teshie Bush Road',
            'latitude': 5.5986,
            'longitude': -0.1067,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Lascala Junction',
            'latitude': 5.6014,
            'longitude': -0.1156,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Tesano',
            'latitude': 5.6081,
            'longitude': -0.1344,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Achimota',
            'latitude': 5.6125,
            'longitude': -0.1556,
            'order': 4,
            'isPickupPoint': true,
            'estimatedTime': '00:25',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:35',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO TESHIE ROUTE (RETURN)
      {
        'id': 'gctu_to_teshie_evening',
        'routeCode': 'GCTU-TSH-E',
        'from': 'GCTU Campus',
        'to': 'Teshie',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Teshie Nungua Estates',
        'estimatedDuration': 35,
        'distance': 18.5,
        'fare': 6.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:30',
            'arrivalTime': '17:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '18:00',
            'arrivalTime': '18:35',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Achimota',
            'latitude': 5.6125,
            'longitude': -0.1556,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Tesano',
            'latitude': 5.6081,
            'longitude': -0.1344,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:20',
          },
          {
            'name': 'Lascala Junction',
            'latitude': 5.6014,
            'longitude': -0.1156,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
          {
            'name': 'Teshie Bush Road',
            'latitude': 5.5986,
            'longitude': -0.1067,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:30',
          },
          {
            'name': 'Teshie Nungua Estates',
            'latitude': 5.5958,
            'longitude': -0.1014,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:35',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // TEMA TO GCTU ROUTE
      {
        'id': 'tema_to_gctu_morning',
        'routeCode': 'TMA-GCTU-M',
        'from': 'Tema',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Tema Station',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 50,
        'distance': 32.0,
        'fare': 10.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '06:00',
            'arrivalTime': '06:50',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '07:15',
            'arrivalTime': '08:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Tema Station',
            'latitude': 5.6698,
            'longitude': -0.0166,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Tema Community 1',
            'latitude': 5.6567,
            'longitude': -0.0234,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Sakumono',
            'latitude': 5.6344,
            'longitude': -0.0456,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Spintex',
            'latitude': 5.6189,
            'longitude': -0.0678,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:25',
          },
          {
            'name': 'East Legon',
            'latitude': 5.6256,
            'longitude': -0.1234,
            'order': 4,
            'isPickupPoint': true,
            'estimatedTime': '00:35',
          },
          {
            'name': 'Shiashie',
            'latitude': 5.6178,
            'longitude': -0.1456,
            'order': 5,
            'isPickupPoint': true,
            'estimatedTime': '00:40',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '00:50',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO TEMA ROUTE (RETURN)
      {
        'id': 'gctu_to_tema_evening',
        'routeCode': 'GCTU-TMA-E',
        'from': 'GCTU Campus',
        'to': 'Tema',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Tema Station',
        'estimatedDuration': 50,
        'distance': 32.0,
        'fare': 10.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:00',
            'arrivalTime': '16:50',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '17:45',
            'arrivalTime': '18:35',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Shiashie',
            'latitude': 5.6178,
            'longitude': -0.1456,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:10',
          },
          {
            'name': 'East Legon',
            'latitude': 5.6256,
            'longitude': -0.1234,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Spintex',
            'latitude': 5.6189,
            'longitude': -0.0678,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
          {
            'name': 'Sakumono',
            'latitude': 5.6344,
            'longitude': -0.0456,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:35',
          },
          {
            'name': 'Tema Community 1',
            'latitude': 5.6567,
            'longitude': -0.0234,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:45',
          },
          {
            'name': 'Tema Station',
            'latitude': 5.6698,
            'longitude': -0.0166,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '00:50',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // NSAWAM TO GCTU ROUTE
      {
        'id': 'nsawam_to_gctu_morning',
        'routeCode': 'NSW-GCTU-M',
        'from': 'Nsawam',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Nsawam Central Market',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 65,
        'distance': 45.0,
        'fare': 12.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '05:30',
            'arrivalTime': '06:35',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '06:45',
            'arrivalTime': '07:50',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Nsawam Central Market',
            'latitude': 5.8089,
            'longitude': -0.3456,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Nsawam Road Junction',
            'latitude': 5.7945,
            'longitude': -0.3378,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Suhum Junction',
            'latitude': 5.7456,
            'longitude': -0.3123,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Adenta',
            'latitude': 5.7089,
            'longitude': -0.2789,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:30',
          },
          {
            'name': 'Madina',
            'latitude': 5.6889,
            'longitude': -0.2456,
            'order': 4,
            'isPickupPoint': true,
            'estimatedTime': '00:40',
          },
          {
            'name': 'Dome',
            'latitude': 5.6567,
            'longitude': -0.2123,
            'order': 5,
            'isPickupPoint': true,
            'estimatedTime': '00:50',
          },
          {
            'name': 'Achimota',
            'latitude': 5.6125,
            'longitude': -0.1556,
            'order': 6,
            'isPickupPoint': true,
            'estimatedTime': '00:60',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 7,
            'isPickupPoint': false,
            'estimatedTime': '01:05',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO NSAWAM ROUTE (RETURN)
      {
        'id': 'gctu_to_nsawam_evening',
        'routeCode': 'GCTU-NSW-E',
        'from': 'GCTU Campus',
        'to': 'Nsawam',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Nsawam Central Market',
        'estimatedDuration': 65,
        'distance': 45.0,
        'fare': 12.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:00',
            'arrivalTime': '17:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '18:00',
            'arrivalTime': '19:05',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Achimota',
            'latitude': 5.6125,
            'longitude': -0.1556,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Dome',
            'latitude': 5.6567,
            'longitude': -0.2123,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Madina',
            'latitude': 5.6889,
            'longitude': -0.2456,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
          {
            'name': 'Adenta',
            'latitude': 5.7089,
            'longitude': -0.2789,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:35',
          },
          {
            'name': 'Suhum Junction',
            'latitude': 5.7456,
            'longitude': -0.3123,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:50',
          },
          {
            'name': 'Nsawam Road Junction',
            'latitude': 5.7945,
            'longitude': -0.3378,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '01:00',
          },
          {
            'name': 'Nsawam Central Market',
            'latitude': 5.8089,
            'longitude': -0.3456,
            'order': 7,
            'isPickupPoint': false,
            'estimatedTime': '01:05',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];
  }

  // Method to upload routes to Firebase
  static Future<void> uploadRoutesToFirebase() async {
    final routes = getAllRoutes();
    final firestore = FirebaseFirestore.instance;

    for (var route in routes) {
      try {
        await firestore.collection('routes').doc(route['id']).set(route);
        print('Successfully uploaded route: ${route['routeCode']}');
      } catch (e) {
        print('Error uploading route ${route['routeCode']}: $e');
      }
    }
  }

  // Get routes by origin
  static List<Map<String, dynamic>> getRoutesByOrigin(String origin) {
    return getAllRoutes().where((route) =>
        route['from'].toString().toLowerCase().contains(origin.toLowerCase())
    ).toList();
  }

  // Get return routes (from GCTU)
  static List<Map<String, dynamic>> getReturnRoutes() {
    return getAllRoutes().where((route) =>
    route['direction'] == 'from_university'
    ).toList();
  }

  // Get routes to GCTU
  static List<Map<String, dynamic>> getToUniversityRoutes() {
    return getAllRoutes().where((route) =>
    route['direction'] == 'to_university'
    ).toList();
  }

  // Get all pickup points for a specific route
  static List<Map<String, dynamic>> getPickupPoints(String routeId) {
    final routes = getAllRoutes();
    final route = routes.firstWhere(
          (r) => r['id'] == routeId,
      orElse: () => {},
    );

    if (route.isEmpty) return [];

    final stops = List<Map<String, dynamic>>.from(route['stops']);
    return stops.where((stop) => stop['isPickupPoint'] == true).toList();
  }

  // Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}