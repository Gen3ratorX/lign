// screens/updated_trip_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';
import 'dart:async';

class TripTrackingScreen extends StatefulWidget {
  final String tripId;

  const TripTrackingScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripTrackingScreenState createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _routeAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _routeAnimation;
  late Animation<double> _pulseAnimation;

  bool showNotification = false;
  Timer? _notificationTimer;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;
  StreamSubscription<Map<String, dynamic>?>? _driverLocationSubscription;

  final LocationService _locationService = LocationService();

  Map<String, dynamic> tripData = {
    'driverName': 'Loading...',
    'vehicleNumber': 'BS204',
    'destination': 'Central Station',
    'nextStop': 'Main Street',
    'estimatedTime': '15 mins to your Destination',
    'route': 'Madina → Central Station',
    'driverLatitude': null,
    'driverLongitude': null,
    'estimatedArrivalMinutes': 15,
  };

  Map<String, dynamic>? driverLocation;
  bool hasDriverLocation = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNotificationCycle();
    _listenToTripUpdates();
    _listenToDriverLocation();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _setupAnimations() {
    _routeAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _routeAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _routeAnimationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _startNotificationCycle() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      setState(() {
        showNotification = !showNotification;
      });
    });
  }

  void _listenToTripUpdates() {
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          final data = snapshot.data() as Map<String, dynamic>;
          tripData = {
            ...tripData,
            ...data,
          };
        });
      }
    });
  }

  void _listenToDriverLocation() {
    _driverLocationSubscription = _locationService
        .getDriverLocationForTrip(widget.tripId)
        .listen((location) {
      setState(() {
        driverLocation = location;
        hasDriverLocation = location != null;

        // Update trip data with latest location info
        if (location != null) {
          tripData['driverLatitude'] = location['latitude'];
          tripData['driverLongitude'] = location['longitude'];
          tripData['estimatedArrivalMinutes'] = location['eta'];
        }
      });
    });
  }

  @override
  void dispose() {
    _routeAnimationController.dispose();
    _pulseController.dispose();
    _notificationTimer?.cancel();
    _tripSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          // Map Background with route
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.grey.withOpacity(0.3),
                ],
              ),
            ),
            child: CustomPaint(
              painter: RoutePainter(_routeAnimation),
            ),
          ),

          // Real-time Driver location marker (moves with actual GPS)
          if (hasDriverLocation) ...[
            _buildRealTimeDriverMarker(),
          ],

          // Static route markers
          _buildRouteMarkers(),

          // Trip notification card
          if (showNotification) ...[
            _buildTripNotificationCard(),
          ],

          // UI Controls
          _buildUIControls(),
        ],
      ),
    );
  }

  Widget _buildRealTimeDriverMarker() {
    // Calculate position based on route progress
    // For demo, we'll animate along the route path
    final progress = _calculateDriverProgress();

    return Positioned(
      top: MediaQuery.of(context).size.height * (0.75 - (progress * 0.5)),
      left: MediaQuery.of(context).size.width * (0.15 + (progress * 0.65)),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  // Speed indicator
                  if (driverLocation?['speed'] != null && driverLocation!['speed'] > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateDriverProgress() {
    // This would normally calculate based on actual GPS coordinates
    // For demo purposes, we'll use a simple time-based progress
    if (!hasDriverLocation) return 0.0;

    // Simulate progress based on time since trip started
    final now = DateTime.now();
    final tripStartTime = tripData['tripStartTime'] != null
        ? (tripData['tripStartTime'] as Timestamp).toDate()
        : now.subtract(const Duration(minutes: 5));

    final elapsedMinutes = now.difference(tripStartTime).inMinutes;
    final totalTripMinutes = tripData['estimatedArrivalMinutes'] ?? 15;

    return (elapsedMinutes / totalTripMinutes).clamp(0.0, 1.0);
  }

  Widget _buildRouteMarkers() {
    return Stack(
      children: [
        // Destination marker
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          right: 50,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        // Intermediate stops
        Positioned(
          top: MediaQuery.of(context).size.height * 0.55,
          right: 80,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),

        // User's pickup location
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          left: MediaQuery.of(context).size.width * 0.15,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripNotificationCard() {
    final etaMinutes = tripData['estimatedArrivalMinutes'] ?? 15;
    final driverName = tripData['driverName'] ?? 'Your Driver';
    final vehicleNumber = tripData['vehicleNumber'] ?? 'BS204';

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasDriverLocation ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDriverLocation
                            ? "$driverName is on the way"
                            : "$driverName will start soon",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Jost',
                        ),
                      ),
                      Text(
                        "Vehicle: $vehicleNumber",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Jost',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Next Stop: ${tripData['nextStop'] ?? 'Main Street'}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Jost',
                      ),
                    ),
                    if (hasDriverLocation && driverLocation?['speed'] != null)
                      Text(
                        "Speed: ${(driverLocation!['speed'] * 3.6).toInt()} km/h",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Jost',
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "ETA: ${etaMinutes} mins",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ],
            ),

            // Real-time status indicator
            if (hasDriverLocation) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Live tracking active",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  if (driverLocation?['lastUpdate'] != null)
                    Text(
                      "Updated ${_getTimeAgo(driverLocation!['lastUpdate'])}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'Jost',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'now';

    final lastUpdate = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 30) {
      return 'now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Widget _buildUIControls() {
    return Stack(
      children: [
        // Back button
        Positioned(
          top: 60,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
        ),

        // Notification bell
        if (!showNotification) ...[
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() => showNotification = true),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (hasDriverLocation)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Map controls
        Positioned(
          bottom: 180,
          right: 20,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // ETA banner (always visible)
        Positioned(
          bottom: 120,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: hasDriverLocation
                  ? const Color(0xFF4A90E2).withOpacity(0.9)
                  : Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasDriverLocation
                  ? "${tripData['estimatedArrivalMinutes'] ?? 15} mins to destination"
                  : "Waiting for driver to start",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Jost',
              ),
            ),
          ),
        ),

        // Bottom navigation
        Positioned(
          bottom: 34,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 180,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const Icon(
                    Icons.home_outlined,
                    color: Color(0xFF4A90E2),
                    size: 28,
                  ),
                  const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RoutePainter extends CustomPainter {
  final Animation<double> animation;

  RoutePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Route path from user location to destination
    final startPoint = Offset(size.width * 0.15, size.height * 0.75);
    final controlPoint1 = Offset(size.width * 0.3, size.height * 0.6);
    final controlPoint2 = Offset(size.width * 0.5, size.height * 0.4);
    final endPoint = Offset(size.width * 0.8, size.height * 0.25);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endPoint.dx, endPoint.dy,
    );

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final extractPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * animation.value,
      );
      canvas.drawPath(extractPath, paint);
    }

    // Animated dots along the route
    if (animation.value > 0.1) {
      final dotPaint = Paint()
        ..color = const Color(0xFF4A90E2)
        ..style = PaintingStyle.fill;

      for (double i = 0; i < animation.value; i += 0.1) {
        final pos = pathMetrics.first.getTangentForOffset(
          pathMetrics.first.length * i,
        )?.position;

        if (pos != null) {
          canvas.drawCircle(pos, 3, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}