// screens/driver_tracking_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'driver_service.dart';
import 'driver_model.dart';
import 'trip_model.dart';
import 'location_service.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({Key? key}) : super(key: key);

  @override
  _DriverTrackingScreenState createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _mapIsReady = false;

  final DriverService _driverService = DriverService();
  final LocationService _locationService = LocationService();

  Driver? currentDriver;
  Map<String, dynamic>? nextTrip;
  bool isOnTrip = false;
  String? currentRouteId;
  List<Trip> activePassengers = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  StreamSubscription<Driver?>? _driverSubscription;
  StreamSubscription<Map<String, dynamic>?>? _locationSubscription;

  // Default location (Accra, Ghana)
  static const LatLng _defaultLocation = LatLng(5.6037, -0.1870);
  LatLng _currentLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDriverData();
    _setupSystemUI();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _loadDriverData() {
    // Listen to driver data changes
    _driverSubscription = _driverService.getCurrentDriverStream().listen(
          (driver) {
        if (mounted) {
          setState(() {
            currentDriver = driver;
            isOnTrip = driver?.currentRoute != null;
            currentRouteId = driver?.currentRoute;
          });

          // Update current location if available
          if (driver?.currentLatitude != null && driver?.currentLongitude != null) {
            _currentLocation = LatLng(driver!.currentLatitude!, driver.currentLongitude!);
            if (_mapIsReady) {
              _moveToDriverLocation();
            }
          }

          // Start location tracking if on trip
          if (isOnTrip && currentRouteId != null) {
            _startLocationTracking();
          } else {
            _stopLocationTracking();
          }

          _loadActivePassengers();
        }
      },
      onError: (error) {
        print('Error loading driver data: $error');
      },
    );
  }

  void _startLocationTracking() {
    if (currentRouteId == null || _locationSubscription != null) return;

    print('Starting location tracking for route: $currentRouteId');
    _locationSubscription = _locationService
        .getDriverLocationForTrip(currentRouteId!)
        .listen(
          (locationData) {
        if (locationData != null && mounted) {
          _updateDriverMarker(locationData);
        }
      },
      onError: (error) {
        print('Location stream error: $error');
      },
    );
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _updateDriverMarker(Map<String, dynamic> locationData) {
    if (!mounted) return;

    final lat = locationData['latitude'] as double;
    final lng = locationData['longitude'] as double;

    setState(() {
      // Remove old driver marker
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');

      // Add updated driver marker
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Driver Location',
            snippet: 'Speed: ${(locationData['speed'] * 3.6).toInt()} km/h',
          ),
        ),
      );

      _currentLocation = LatLng(lat, lng);
    });

    // Move camera to follow driver
    if (_mapIsReady && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  void _setupMapData() {
    // Add static route markers
    _markers.addAll({
      Marker(
        markerId: const MarkerId('start'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start Point'),
      ),
      Marker(
        markerId: const MarkerId('stop1'),
        position: LatLng(_currentLocation.latitude + 0.01, _currentLocation.longitude + 0.01),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Stop 1'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(_currentLocation.latitude + 0.02, _currentLocation.longitude + 0.02),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End Point'),
      ),
    });

    // Add route polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          _currentLocation,
          LatLng(_currentLocation.latitude + 0.01, _currentLocation.longitude + 0.01),
          LatLng(_currentLocation.latitude + 0.02, _currentLocation.longitude + 0.02),
        ],
        color: const Color(0xFF4A90E2),
        width: 5,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _mapIsReady = true;
    _setupMapData();
    _moveToDriverLocation();
  }

  void _moveToDriverLocation() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15.0),
      );
    }
  }

  void _loadActivePassengers() async {
    if (currentDriver?.currentRoute != null) {
      try {
        final passengers = await _driverService.getActivePassengers();
        if (mounted) {
          setState(() {
            activePassengers = passengers;
          });
        }
      } catch (e) {
        print('Error loading active passengers: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _driverSubscription?.cancel();
    _locationSubscription?.cancel();
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
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 13.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
          ),

          // UI Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showPassengerList,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(Icons.people, color: Colors.white),
                          ),
                          if (activePassengers.isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${activePassengers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Driver info card
          if (currentDriver != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: _buildDriverInfoCard(),
            ),

          // Map controls
          Positioned(
            bottom: 180,
            right: 20,
            child: Column(
              children: [
                _buildMapControl(Icons.my_location, onTap: _moveToDriverLocation),
                const SizedBox(height: 12),
                _buildMapControl(Icons.zoom_in, onTap: _zoomIn),
                const SizedBox(height: 12),
                _buildMapControl(Icons.zoom_out, onTap: _zoomOut),
              ],
            ),
          ),

          // Control buttons
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentDriver?.name ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          currentDriver?.formattedRating ?? '4.5',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Jost'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currentDriver?.busNumber ?? 'BS204',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Jost'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnTrip ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnTrip ? 'ON TRIP' : 'READY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOnTrip ? Colors.green : Colors.orange,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ],
          ),

          if (isOnTrip && currentRouteId != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Color(0xFF4A90E2)),
                const SizedBox(width: 8),
                Text(
                  'Route: $currentRouteId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
                const Spacer(),
                Text(
                  'Passengers: ${activePassengers.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Jost',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        if (!isOnTrip)
          Expanded(
            child: ElevatedButton(
              onPressed: _startTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Start Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Jost',
                ),
              ),
            ),
          ),
        if (isOnTrip)
          Expanded(
            child: ElevatedButton(
              onPressed: _completeTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'End Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Jost',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _startTrip() async {
    if (currentDriver?.assignedRoutes.isNotEmpty == true) {
      try {
        final routeId = currentDriver!.assignedRoutes.first;
        await _driverService.startRoute(routeId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip started successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting trip: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routes assigned to start trip')),
      );
    }
  }

  void _completeTrip() async {
    if (currentRouteId != null) {
      try {
        await _driverService.completeRoute(currentRouteId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing trip: $e')),
          );
        }
      }
    }
  }

  void _zoomIn() async {
    if (mapController != null) {
      await mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  void _zoomOut() async {
    if (mapController != null) {
      await mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  void _showPassengerList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPassengerListModal(),
    );
  }

  Widget _buildPassengerListModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Passengers (${activePassengers.length})",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Jost',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: activePassengers.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active passengers',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: activePassengers.length,
              itemBuilder: (context, index) {
                final passenger = activePassengers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${passenger.from} → ${passenger.to}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Jost',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${passenger.status}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Jost',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: passenger.status == 'active'
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          passenger.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: passenger.status == 'active'
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontFamily: 'Jost',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}