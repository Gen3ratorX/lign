import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'location_service.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_navigation.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({Key? key}) : super(key: key);

  @override
  _CommuterHomeScreenState createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool hasActiveTrip = false;
  Map<String, dynamic>? currentTrip;
  int selectedBottomNavIndex = 1;

  // Default location (Accra, Ghana based on your user location)
  static const LatLng _defaultLocation = LatLng(5.6037, -0.1870);
  LatLng _currentLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenToTripUpdates();
    _setupMapMarkers();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _initializeLocation() async {
    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _currentPosition = position;
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentLocation),
        );
      }
    }
  }

  Future<void> _setupMapMarkers() async {
    // Create custom markers
    final restaurantIcon = await _createCustomMarker(
      Icons.restaurant,
      Colors.orange,
      40.0,
    );

    final busStopIcon = await _createCustomMarker(
      Icons.directions_bus_filled,
      Colors.blue,
      40.0,
    );

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('restaurant1'),
          position: const LatLng(5.6137, -0.1770), // Offset from center
          icon: restaurantIcon,
          infoWindow: const InfoWindow(
            title: 'Restaurant',
            snippet: 'Popular dining spot',
          ),
        ),
        Marker(
          markerId: const MarkerId('busstop1'),
          position: const LatLng(5.5937, -0.1970), // Another location
          icon: busStopIcon,
          infoWindow: const InfoWindow(
            title: 'Bus Stop',
            snippet: 'Main Street Station',
          ),
        ),
      };
    });
  }

  Future<BitmapDescriptor> _createCustomMarker(
      IconData iconData,
      Color color,
      double size,
      ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) * 0.5,
        (size - textPainter.height) * 0.5,
      ),
    );

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _listenToTripUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'ongoing'])
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            hasActiveTrip = true;
            currentTrip = snapshot.docs.first.data();
          });
          _updateTripRoute();
        } else {
          setState(() {
            hasActiveTrip = false;
            currentTrip = null;
            _polylines.clear();
          });
        }
      });
    }
  }

  void _updateTripRoute() {
    if (currentTrip == null) return;

    // Create route polyline for active trip
    final routePoints = [
      _currentLocation,
      const LatLng(5.6137, -0.1570), // Intermediate point
      const LatLng(5.6237, -0.1370), // Destination
    ];

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('activeRoute'),
          points: routePoints,
          color: const Color(0xFF4A90E2),
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Apply custom map style
    _setMapStyle();

    // Move to current location if available
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(_currentLocation),
      );
    }
  }

  void _setMapStyle() async {
    String mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e5e5e5"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#dadada"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#c9c9c9"
          }
        ]
      }
    ]
    ''';

    _mapController?.setMapStyle(mapStyle);
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
              zoom: 14.0,
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
            onTap: (LatLng position) {
              print('Map tapped at: ${position.latitude}, ${position.longitude}');
            },
          ),

          // Input your stop (when no active trip)
          if (!hasActiveTrip) ...[
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _showDestinationInput(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "Input your stop",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Map Controls
          Positioned(
            bottom: hasActiveTrip ? 220 : 380,
            right: 20,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                  child: IconButton(
                    onPressed: _goToCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 48,
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
                  child: IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(
                      Icons.add,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active trip info (when trip is active)
          if (hasActiveTrip) ...[
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: _buildActiveTrip(),
            ),
            Positioned(
              top: 260,
              left: 20,
              right: 20,
              child: _buildTripStatus(),
            ),
          ],

          // Bottom content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: hasActiveTrip ? Container() : _buildTripsSection(),
          ),

          // Bottom Navigation
          AppBottomNavigation(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildActiveTrip() {
    if (currentTrip == null) return Container();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 8),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.directions_bus, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jon Doe is on the way",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Jost',
                      ),
                    ),
                    Text(
                      "Arrived: Downtown Terminal — 10:30 AM",
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.directions_bus, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Final Destination: Central Station",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Jost',
                    ),
                  ),
                  Text(
                    "Next Stop: Main Street (10 min trip)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            "On time",
            style: TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "ETA: 7:43AM",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "OTW",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Jost',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trips",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 20),

          // Trip options
          _buildTripOption(
            icon: Icons.directions_bus,
            iconColor: Colors.orange,
            title: "Book Now",
            subtitle: "Want to grab the next available seat?",
            actionColor: Colors.blue,
            onTap: () {
              print('Navigating to /booking');
              context.push('/booking');
            },
          ),

          _buildTripOption(
            icon: Icons.storage,
            iconColor: Colors.grey[600]!,
            title: "My Trips",
            subtitle: "Want to view your past rides?",
            actionColor: Colors.purple,
            onTap: () {
              print('Navigating to /my_trips');
              context.push('/my_trips');
            },
          ),

          _buildTripOption(
            icon: Icons.hub,
            iconColor: Colors.grey[600]!,
            title: "Incoming",
            subtitle: "Want to check todays Departures?",
            actionColor: Colors.red,
            onTap: () {
              print('Navigating to /incoming');
              context.push('/incoming');
            },
          ),

          _buildTripOption(
            icon: Icons.map,
            iconColor: Colors.green,
            title: "Schedule",
            subtitle: "Look for nearby pickup points",
            actionColor: Colors.grey[400]!,
            onTap: () {
              print('Navigating to /schedules');
              context.push('/schedules');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor == Colors.orange ? Colors.orange : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor == Colors.orange ? Colors.white : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(title),
                  color: actionColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String title) {
    switch (title) {
      case 'Book Now':
        return Icons.directions_bus;
      case 'My Trips':
        return Icons.search;
      case 'Incoming':
        return Icons.calendar_today;
      case 'Schedule':
        return Icons.map;
      default:
        return Icons.arrow_forward;
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      selectedBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        print('Navigating to /tickets');
        context.push('/tickets');
        break;
      case 1:
      // Already on home
        break;
      case 2:
        print('Navigating to /profile_settings');
        context.push('/profile_settings');
        break;
    }
  }

  void _showDestinationInput() {
    print('Navigating to /booking');
    context.push('/booking');
  }

  void _goToCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    } else {
      // Request location again
      await _initializeLocation();
    }
  }

  void _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }
}