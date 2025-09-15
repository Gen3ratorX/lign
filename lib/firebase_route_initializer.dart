
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRouteInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize all GCTU routes in Firebase
  static Future<void> initializeGCTURoutes() async {
    print('Starting GCTU routes initialization...');

    try {
      // Check if routes already exist
      final existingRoutes = await _firestore.collection('routes').limit(1).get();
      if (existingRoutes.docs.isNotEmpty) {
        print('Routes already exist. Skipping initialization.');
        return;
      }

      final routes = _getAllGCTURoutes();
      final batch = _firestore.batch();

      for (var route in routes) {
        final docRef = _firestore.collection('routes').doc(route['id']);
        batch.set(docRef, route);
      }

      await batch.commit();
      print('Successfully initialized ${routes.length} GCTU routes');
    } catch (e) {
      print('Error initializing routes: $e');
      throw Exception('Failed to initialize routes: $e');
    }
  }

  // Force update all routes (use carefully)
  static Future<void> updateAllRoutes() async {
    print('Updating all GCTU routes...');

    try {
      final routes = _getAllGCTURoutes();
      final batch = _firestore.batch();

      for (var route in routes) {
        final docRef = _firestore.collection('routes').doc(route['id']);
        batch.set(docRef, route, SetOptions(merge: true));
      }

      await batch.commit();
      print('Successfully updated ${routes.length} GCTU routes');
    } catch (e) {
      print('Error updating routes: $e');
      throw Exception('Failed to update routes: $e');
    }
  }

  // Delete all routes (use very carefully)
  static Future<void> deleteAllRoutes() async {
    print('Deleting all routes...');

    try {
      final snapshot = await _firestore.collection('routes').get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Successfully deleted ${snapshot.docs.length} routes');
    } catch (e) {
      print('Error deleting routes: $e');
      throw Exception('Failed to delete routes: $e');
    }
  }

  // Get route statistics
  static Future<Map<String, dynamic>> getRouteStatistics() async {
    try {
      final snapshot = await _firestore.collection('routes').get();
      final routes = snapshot.docs.map((doc) => doc.data()).toList();

      final toUniversityCount = routes.where((r) => r['direction'] == 'to_university').length;
      final fromUniversityCount = routes.where((r) => r['direction'] == 'from_university').length;
      final activeCount = routes.where((r) => r['isActive'] == true).length;

      final origins = routes.map((r) => r['from']).toSet().toList();
      final totalStops = routes.fold<int>(0, (sum, route) {
        final stops = List.from(route['stops'] ?? []);
        return sum + stops.length;
      });

      return {
        'totalRoutes': routes.length,
        'toUniversityRoutes': toUniversityCount,
        'fromUniversityRoutes': fromUniversityCount,
        'activeRoutes': activeCount,
        'uniqueOrigins': origins.length,
        'totalStops': totalStops,
        'origins': origins,
      };
    } catch (e) {
      print('Error getting route statistics: $e');
      return {};
    }
  }

  static List<Map<String, dynamic>> _getAllGCTURoutes() {
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
        'estimatedDuration': 45,
        'distance': 28.5,
        'fare': 8.00,
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
            'departureTime': '16:15',
            'arrivalTime': '17:05',
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
        'departureLocation': 'Nsawam Station',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 60,
        'distance': 45.0,
        'fare': 12.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '05:30',
            'arrivalTime': '06:30',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '06:45',
            'arrivalTime': '07:45',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Nsawam Station',
            'latitude': 5.8089,
            'longitude': -0.3500,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Suhum Junction',
            'latitude': 5.7956,
            'longitude': -0.3223,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Koforidua Road',
            'latitude': 5.7567,
            'longitude': -0.2890,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:20',
          },
          {
            'name': 'Adenta',
            'latitude': 5.7089,
            'longitude': -0.2445,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:35',
          },
          {
            'name': 'Madina',
            'latitude': 5.6834,
            'longitude': -0.2178,
            'order': 4,
            'isPickupPoint': true,
            'estimatedTime': '00:45',
          },
          {
            'name': 'Legon',
            'latitude': 5.6456,
            'longitude': -0.1889,
            'order': 5,
            'isPickupPoint': true,
            'estimatedTime': '00:55',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '01:00',
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
        'arrivalLocation': 'Nsawam Station',
        'estimatedDuration': 60,
        'distance': 45.0,
        'fare': 12.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:00',
            'arrivalTime': '17:00',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '17:30',
            'arrivalTime': '18:30',
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
            'name': 'Legon',
            'latitude': 5.6456,
            'longitude': -0.1889,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Madina',
            'latitude': 5.6834,
            'longitude': -0.2178,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Adenta',
            'latitude': 5.7089,
            'longitude': -0.2445,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
          {
            'name': 'Koforidua Road',
            'latitude': 5.7567,
            'longitude': -0.2890,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:40',
          },
          {
            'name': 'Suhum Junction',
            'latitude': 5.7956,
            'longitude': -0.3223,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:50',
          },
          {
            'name': 'Nsawam Station',
            'latitude': 5.8089,
            'longitude': -0.3500,
            'order': 6,
            'isPickupPoint': false,
            'estimatedTime': '01:00',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // CIRCLE TO GCTU ROUTE
      {
        'id': 'circle_to_gctu_morning',
        'routeCode': 'CIR-GCTU-M',
        'from': 'Circle',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Circle VIP Station',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 25,
        'distance': 12.0,
        'fare': 4.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '07:00',
            'arrivalTime': '07:25',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '08:00',
            'arrivalTime': '08:25',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Circle VIP Station',
            'latitude': 5.5644,
            'longitude': -0.1958,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Lapaz',
            'latitude': 5.5756,
            'longitude': -0.1867,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:05',
          },
          {
            'name': 'Santa Maria',
            'latitude': 5.5889,
            'longitude': -0.1834,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Achimota Forest',
            'latitude': 5.5978,
            'longitude': -0.1823,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'GCTU Main Gate',
            'latitude': 5.6037,
            'longitude': -0.1870,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO CIRCLE ROUTE (RETURN)
      {
        'id': 'gctu_to_circle_evening',
        'routeCode': 'GCTU-CIR-E',
        'from': 'GCTU Campus',
        'to': 'Circle',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Circle VIP Station',
        'estimatedDuration': 25,
        'distance': 12.0,
        'fare': 4.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '16:45',
            'arrivalTime': '17:10',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '18:15',
            'arrivalTime': '18:40',
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
            'name': 'Achimota Forest',
            'latitude': 5.5978,
            'longitude': -0.1823,
            'order': 1,
            'isPickupPoint': false,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Santa Maria',
            'latitude': 5.5889,
            'longitude': -0.1834,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Lapaz',
            'latitude': 5.5756,
            'longitude': -0.1867,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:20',
          },
          {
            'name': 'Circle VIP Station',
            'latitude': 5.5644,
            'longitude': -0.1958,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:25',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // ABLEKUMA TO GCTU ROUTE
      {
        'id': 'ablekuma_to_gctu_morning',
        'routeCode': 'ABL-GCTU-M',
        'from': 'Ablekuma',
        'to': 'GCTU Campus',
        'direction': 'to_university',
        'departureLocation': 'Ablekuma Market',
        'arrivalLocation': 'GCTU Main Gate',
        'estimatedDuration': 30,
        'distance': 15.5,
        'fare': 5.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '06:45',
            'arrivalTime': '07:15',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '07:45',
            'arrivalTime': '08:15',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
        ],
        'stops': [
          {
            'name': 'Ablekuma Market',
            'latitude': 5.5456,
            'longitude': -0.2123,
            'order': 0,
            'isPickupPoint': true,
            'estimatedTime': '00:00',
          },
          {
            'name': 'Odorkor',
            'latitude': 5.5567,
            'longitude': -0.2045,
            'order': 1,
            'isPickupPoint': true,
            'estimatedTime': '00:08',
          },
          {
            'name': 'Russia Junction',
            'latitude': 5.5689,
            'longitude': -0.1956,
            'order': 2,
            'isPickupPoint': true,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Lapaz',
            'latitude': 5.5756,
            'longitude': -0.1867,
            'order': 3,
            'isPickupPoint': true,
            'estimatedTime': '00:20',
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
            'estimatedTime': '00:30',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },

      // GCTU TO ABLEKUMA ROUTE (RETURN)
      {
        'id': 'gctu_to_ablekuma_evening',
        'routeCode': 'GCTU-ABL-E',
        'from': 'GCTU Campus',
        'to': 'Ablekuma',
        'direction': 'from_university',
        'departureLocation': 'GCTU Main Gate',
        'arrivalLocation': 'Ablekuma Market',
        'estimatedDuration': 30,
        'distance': 15.5,
        'fare': 5.00,
        'capacity': 35,
        'isActive': true,
        'schedules': [
          {
            'departureTime': '17:00',
            'arrivalTime': '17:30',
            'frequency': 'daily',
            'daysOfWeek': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          },
          {
            'departureTime': '18:30',
            'arrivalTime': '19:00',
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
            'name': 'Lapaz',
            'latitude': 5.5756,
            'longitude': -0.1867,
            'order': 2,
            'isPickupPoint': false,
            'estimatedTime': '00:10',
          },
          {
            'name': 'Russia Junction',
            'latitude': 5.5689,
            'longitude': -0.1956,
            'order': 3,
            'isPickupPoint': false,
            'estimatedTime': '00:15',
          },
          {
            'name': 'Odorkor',
            'latitude': 5.5567,
            'longitude': -0.2045,
            'order': 4,
            'isPickupPoint': false,
            'estimatedTime': '00:22',
          },
          {
            'name': 'Ablekuma Market',
            'latitude': 5.5456,
            'longitude': -0.2123,
            'order': 5,
            'isPickupPoint': false,
            'estimatedTime': '00:30',
          },
        ],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];
  }

  // Helper method to add a single route
  static Future<void> addSingleRoute(Map<String, dynamic> route) async {
    try {
      await _firestore.collection('routes').doc(route['id']).set(route);
      print('Successfully added route: ${route['routeCode']}');
    } catch (e) {
      print('Error adding route: $e');
      throw Exception('Failed to add route: $e');
    }
  }

  // Helper method to update a single route
  static Future<void> updateSingleRoute(String routeId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('routes').doc(routeId).update(updates);
      print('Successfully updated route: $routeId');
    } catch (e) {
      print('Error updating route: $e');
      throw Exception('Failed to update route: $e');
    }
  }

  // Helper method to deactivate a route
  static Future<void> deactivateRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      print('Successfully deactivated route: $routeId');
    } catch (e) {
      print('Error deactivating route: $e');
      throw Exception('Failed to deactivate route: $e');
    }
  }

  // Helper method to activate a route
  static Future<void> activateRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'isActive': true,
        'updatedAt': Timestamp.now(),
      });
      print('Successfully activated route: $routeId');
    } catch (e) {
      print('Error activating route: $e');
      throw Exception('Failed to activate route: $e');
    }
  }

  // Method to get all route IDs for reference
  static List<String> getAllRouteIds() {
    return _getAllGCTURoutes().map((route) => route['id'] as String).toList();
  }

  // Method to get routes by direction
  static List<Map<String, dynamic>> getRoutesByDirection(String direction) {
    return _getAllGCTURoutes()
        .where((route) => route['direction'] == direction)
        .toList();
  }

  // Method to get routes by origin
  static List<Map<String, dynamic>> getRoutesByOrigin(String origin) {
    return _getAllGCTURoutes()
        .where((route) => route['from'].toString().toLowerCase().contains(origin.toLowerCase()))
        .toList();
  }
}