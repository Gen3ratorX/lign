import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomingScreen extends StatefulWidget {
  const IncomingScreen({Key? key}) : super(key: key);

  @override
  _IncomingScreenState createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  List<Map<String, dynamic>> nextTrips = [];
  List<Map<String, dynamic>> upcomingTrips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomingTrips();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadIncomingTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Load confirmed trips (today)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final confirmedSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('departureTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('departureTime')
          .get();

      // Load upcoming trips (tomorrow and beyond)
      final upcomingSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['booked', 'confirmed'])
          .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('departureTime')
          .get();

      setState(() {
        nextTrips = confirmedSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        upcomingTrips = upcomingSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trips: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Incoming",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.menu,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Next Trip Section
                      if (nextTrips.isNotEmpty) ...[
                        const Text(
                          "Next Trip",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Jost',
                          ),
                        ),

                        const SizedBox(height: 16),

                        ...nextTrips.map((trip) => _buildConfirmedTripCard(trip)),

                        const SizedBox(height: 32),
                      ],

                      // Other Upcoming Trips Section
                      const Text(
                        "Other Upcoming Trips",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Jost',
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (upcomingTrips.isEmpty)
                        _buildEmptyUpcomingState()
                      else
                        ...upcomingTrips.map((trip) => _buildUpcomingTripCard(trip)),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 34),
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
                      const Icon(
                        Icons.directions_bus_outlined,
                        color: Colors.white,
                        size: 24,
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
        ),
      ),
    );
  }

  Widget _buildConfirmedTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    "A",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                "Confirmed",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                  fontFamily: 'Jost',
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      trip['busNumber'] ?? 'BS204',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trip['from'] ?? 'Accra'} → ${trip['to'] ?? 'Kumasi'}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(trip['departureTime']),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "View Ticket",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripCard(Map<String, dynamic> trip) {
    final isTomorrow = _isTomorrow(trip['departureTime']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.orange,
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                isTomorrow ? "Tomorrow" : "Upcoming",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isTomorrow ? Colors.orange : Colors.grey[600],
                  fontFamily: 'Jost',
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      trip['busNumber'] ?? 'BS204',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trip['from'] ?? 'Accra'} → ${trip['to'] ?? 'Kumasi'}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(trip['departureTime']),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "View Ticket",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcomingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No upcoming trips",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Book a new trip to see it here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Jost',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "28 June 2025";

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return "28 June 2025";
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  bool _isTomorrow(dynamic timestamp) {
    if (timestamp == null) return false;

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return false;
    }

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayAfterTomorrow = DateTime(now.year, now.month, now.day + 2);

    return date.isAfter(tomorrow) && date.isBefore(dayAfterTomorrow);
  }
}
