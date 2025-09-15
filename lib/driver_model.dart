// models/driver_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String name;
  final String busNumber;
  final String licenseNumber;
  final String phoneNumber;
  final bool isOnDuty;
  final double rating;
  final int capacity;
  final List<String> assignedRoutes;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentRoute;
  final DateTime? shiftStartTime;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  Driver({
    required this.id,
    required this.name,
    required this.busNumber,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.isOnDuty,
    required this.rating,
    required this.capacity,
    required this.assignedRoutes,
    this.currentLatitude,
    this.currentLongitude,
    this.currentRoute,
    this.shiftStartTime,
    this.createdAt,
    this.lastUpdated,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: data['name'] ?? '',
      busNumber: data['busNumber'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      isOnDuty: data['isOnDuty'] ?? false,
      rating: (data['rating'] ?? 4.5).toDouble(),
      capacity: data['capacity'] ?? 15,
      assignedRoutes: List<String>.from(data['assignedRoutes'] ?? []),
      currentLatitude: data['currentLatitude']?.toDouble(),
      currentLongitude: data['currentLongitude']?.toDouble(),
      currentRoute: data['currentRoute'],
      shiftStartTime: data['shiftStartTime'] != null
          ? (data['shiftStartTime'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'busNumber': busNumber,
      'licenseNumber': licenseNumber,
      'phoneNumber': phoneNumber,
      'isOnDuty': isOnDuty,
      'rating': rating,
      'capacity': capacity,
      'assignedRoutes': assignedRoutes,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'currentRoute': currentRoute,
      'shiftStartTime': shiftStartTime != null
          ? Timestamp.fromDate(shiftStartTime!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
      'lastUpdated': Timestamp.now(),
    };
  }

  // Helper methods
  String get formattedRating => rating.toStringAsFixed(1);

  bool get hasActiveRoute => currentRoute != null && isOnDuty;

  String get statusText => isOnDuty ? 'On Duty' : 'Off Duty';

  int get availableSeats => capacity;

  // Create a copy with updated fields
  Driver copyWith({
    String? name,
    String? busNumber,
    String? licenseNumber,
    String? phoneNumber,
    bool? isOnDuty,
    double? rating,
    int? capacity,
    List<String>? assignedRoutes,
    double? currentLatitude,
    double? currentLongitude,
    String? currentRoute,
    DateTime? shiftStartTime,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      busNumber: busNumber ?? this.busNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      rating: rating ?? this.rating,
      capacity: capacity ?? this.capacity,
      assignedRoutes: assignedRoutes ?? this.assignedRoutes,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentRoute: currentRoute ?? this.currentRoute,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}