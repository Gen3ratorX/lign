import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String? routeId;

  const RouteDetailsScreen({Key? key, this.routeId}) : super(key: key);

  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  Map<String, dynamic> routeData = {
    'from': 'Current Location',
    'to': 'Achimota',
    'routeId': 'BUS-201',
    'departureTime': '4mins',
    'duration': '25mins',
    'keyStops': 2,
    'availableSeats': 10,
    'price': 'GHS 4.00',
    'isRecommended': true,
  };

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.routeId != null) {
      _loadRouteDetails();
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadRouteDetails() async {
    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.routeId)
          .get();

      if (doc.exists) {
        setState(() {
          routeData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading route details: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Map background (blurred)
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
          ),
          // Back Button
          Positioned(
            top: 70,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          "Hop On This One!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Jost',
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "This route is one of the fastest available. If it doesn't suit you, tap 'Next' to view other options",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Jost',
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Route Details
                        _buildDetailRow(
                          "From",
                          routeData['from'] ?? 'Current Location',
                          Icons.my_location,
                          const Color(0xFF4A90E2),
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "To",
                          routeData['to'] ?? 'Achimota',
                          Icons.location_on,
                          Colors.grey[500]!,
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Route ID",
                          routeData['routeId'] ?? 'BUS-201',
                          Icons.directions_bus,
                          const Color(0xFF4A90E2),
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Departure Time",
                          routeData['departureTime'] ?? '4mins',
                          Icons.access_time,
                          const Color(0xFF4A90E2),
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Duration",
                          routeData['duration'] ?? '25mins',
                          Icons.schedule,
                          Colors.orange,
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Key Stops",
                          "${routeData['keyStops'] ?? 2}",
                          Icons.location_on,
                          Colors.green,
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Availability",
                          "${routeData['availableSeats'] ?? 10} seats Left",
                          Icons.event_seat,
                          Colors.purple,
                        ),

                        const SizedBox(height: 20),

                        _buildDetailRow(
                          "Price",
                          routeData['price'] ?? 'GHS 4.00',
                          Icons.attach_money,
                          Colors.green,
                        ),

                        const SizedBox(height: 40),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: _showNextRoute,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Jost',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _bookNow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "Book Now",
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
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontFamily: 'Jost',
            ),
          ),
        ),

        const SizedBox(width: 20),

        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Jost',
            ),
          ),
        ),
      ],
    );
  }

  void _showNextRoute() {
    // Show next available route
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading next route...')),
    );

    // You can implement route cycling logic here
    Navigator.pop(context);
  }

  void _bookNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a trip')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create trip booking
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'routeId': routeData['routeId'],
        'from': routeData['from'],
        'to': routeData['to'],
        'departureTime': Timestamp.now().toDate().add(
            Duration(minutes: int.tryParse(routeData['departureTime'].replaceAll('mins', '')) ?? 4)
        ),
        'duration': routeData['duration'],
        'price': routeData['price'],
        'status': 'booked',
        'bookingTime': Timestamp.now(),
        'availableSeats': routeData['availableSeats'],
      });

      setState(() => isLoading = false);

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to trip tracking or home
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/commuter_home');

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }
}

