// screens/driver_route_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gctu_route_service.dart';
import 'driver_service.dart';

class DriverRouteSelectionScreen extends StatefulWidget {
  const DriverRouteSelectionScreen({Key? key}) : super(key: key);

  @override
  _DriverRouteSelectionScreenState createState() => _DriverRouteSelectionScreenState();
}

class _DriverRouteSelectionScreenState extends State<DriverRouteSelectionScreen> {
  final GCTURouteService _routeService = GCTURouteService();
  final DriverService _driverService = DriverService();

  List<Map<String, dynamic>> availableRoutes = [];
  List<String> selectedRoutes = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String? driverName;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _loadAvailableRoutes();
    _loadSelectedRoutes();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadDriverInfo() async {
    try {
      final driver = await _driverService.getCurrentDriver();
      if (mounted) {
        setState(() {
          driverName = driver?.name ?? 'Driver';
        });
      }
    } catch (e) {
      print('Error loading driver info: $e');
    }
  }

  void _loadAvailableRoutes() async {
    setState(() => isLoading = true);

    try {
      // Get all active routes
      final toUniversityRoutes = await _routeService.getToUniversityRoutes();
      final fromUniversityRoutes = await _routeService.getFromUniversityRoutes();

      // Combine and filter routes for the selected date
      final allRoutes = [...toUniversityRoutes, ...fromUniversityRoutes];
      final filteredRoutes = allRoutes.where((route) {
        return _routeService.isRouteAvailableOnDay(route, selectedDate);
      }).toList();

      if (mounted) {
        setState(() {
          availableRoutes = filteredRoutes;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: $e')),
        );
      }
    }
  }

  void _loadSelectedRoutes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dateStr = _formatDate(selectedDate);
      final doc = await FirebaseFirestore.instance
          .collection('driver_schedules')
          .doc('${user.uid}_$dateStr')
          .get();

      if (doc.exists && mounted) {
        setState(() {
          selectedRoutes = List<String>.from(doc.data()?['selectedRoutes'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading selected routes: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Select Routes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Jost',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: selectedRoutes.isNotEmpty ? _saveSelectedRoutes : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: selectedRoutes.isNotEmpty ? const Color(0xFF4A90E2) : Colors.grey,
                fontWeight: FontWeight.w600,
                fontFamily: 'Jost',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF4A90E2)),
                    const SizedBox(width: 8),
                    Text(
                      'Welcome, ${driverName ?? 'Driver'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Select your routes for ${_formatDisplayDate(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Jost',
                  ),
                ),
              ],
            ),
          ),

          // Date Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF4A90E2)),
                const SizedBox(width: 8),
                const Text(
                  'Date:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDisplayDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected Routes Summary
          if (selectedRoutes.isNotEmpty) ...[
            Container(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedRoutes.length} route${selectedRoutes.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Routes List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableRoutes.isEmpty
                ? _buildEmptyState()
                : _buildRoutesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No routes available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'for ${_formatDisplayDate(selectedDate)}',
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

  Widget _buildRoutesList() {
    // Group routes by direction
    final toUniversityRoutes = availableRoutes
        .where((route) => route['direction'] == 'to_university')
        .toList();
    final fromUniversityRoutes = availableRoutes
        .where((route) => route['direction'] == 'from_university')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (toUniversityRoutes.isNotEmpty) ...[
          _buildSectionHeader('To GCTU Campus', toUniversityRoutes.length),
          const SizedBox(height: 12),
          ...toUniversityRoutes.map((route) => _buildRouteCard(route)),
          const SizedBox(height: 24),
        ],
        if (fromUniversityRoutes.isNotEmpty) ...[
          _buildSectionHeader('From GCTU Campus', fromUniversityRoutes.length),
          const SizedBox(height: 12),
          ...fromUniversityRoutes.map((route) => _buildRouteCard(route)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Jost',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isSelected = selectedRoutes.contains(route['id']);
    final schedules = List<Map<String, dynamic>>.from(route['schedules'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleRouteSelection(route['id']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      route['routeCode'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4A90E2),
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${route['from']} → ${route['to']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Jost',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${route['estimatedDuration']} min',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${route['distance']} km',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
              if (schedules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Departure Times:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontFamily: 'Jost',
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: schedules.map((schedule) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A90E2).withOpacity(0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule['departureTime'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[600],
                          fontFamily: 'Jost',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleRouteSelection(String routeId) {
    setState(() {
      if (selectedRoutes.contains(routeId)) {
        selectedRoutes.remove(routeId);
      } else {
        selectedRoutes.add(routeId);
      }
    });
  }

  void _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day); // Start of today

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today, // Allow selection from today (not tomorrow)
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select route date',
      confirmText: 'SELECT',
      cancelText: 'CANCEL',
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedRoutes.clear();
      });
      _loadAvailableRoutes();
      _loadSelectedRoutes();
    }
  }

  String _formatDisplayDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _saveSelectedRoutes() async {
    if (selectedRoutes.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final dateStr = _formatDate(selectedDate);

      // Save to driver_schedules collection
      await FirebaseFirestore.instance
          .collection('driver_schedules')
          .doc('${user.uid}_$dateStr')
          .set({
        'driverId': user.uid,
        'date': Timestamp.fromDate(selectedDate),
        'selectedRoutes': selectedRoutes,
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update driver's current assignment for today
      if (_isToday(selectedDate)) {
        await _driverService.updateDriverProfile(
          assignedRoutes: selectedRoutes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routes saved for ${_formatDisplayDate(selectedDate)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving routes: $e')),
        );
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// Enhanced driver service methods for route selection
extension DriverRouteSelection on DriverService {
  // Get driver's schedule for a specific date
  Future<List<String>> getDriverScheduleForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await FirebaseFirestore.instance
          .collection('driver_schedules')
          .doc('${user.uid}_$dateStr')
          .get();

      if (doc.exists) {
        return List<String>.from(doc.data()?['selectedRoutes'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting driver schedule: $e');
      return [];
    }
  }

  // Check if driver has routes selected for today
  Future<bool> hasRoutesForToday() async {
    final routes = await getDriverScheduleForDate(DateTime.now());
    return routes.isNotEmpty;
  }

  // Get next trip with proper route filtering
  Future<Map<String, dynamic>?> getNextTripFromSelectedRoutes() async {
    final driver = await getCurrentDriver();
    if (driver == null) return null;

    // Get today's selected routes
    final todaysRoutes = await getDriverScheduleForDate(DateTime.now());
    if (todaysRoutes.isEmpty) return null;

    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('routeId', whereIn: todaysRoutes)
          .where('status', isEqualTo: 'booked')
          .where('departureTime', isGreaterThan: now)
          .orderBy('departureTime')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final trip = snapshot.docs.first;
        final tripData = trip.data();

        // Get passenger count for this trip
        final passengerCount = await _getPassengerCountForRoute(
          tripData['routeId'],
          (tripData['departureTime'] as Timestamp).toDate(),
        );

        return {
          'tripId': trip.id,
          'route': '${tripData['from']} → ${tripData['to']}',
          'departureTime': (tripData['departureTime'] as Timestamp).toDate(),
          'passengerCount': passengerCount,
          'capacity': driver.capacity,
          'routeId': tripData['routeId'],
          'from': tripData['from'],
          'to': tripData['to'],
        };
      }
    } catch (e) {
      print('Error getting next trip from selected routes: $e');
    }

    return null;
  }

  Future<int> _getPassengerCountForRoute(String routeId, DateTime departureTime) async {
    try {
      final startOfHour = DateTime(
        departureTime.year,
        departureTime.month,
        departureTime.day,
        departureTime.hour,
      );
      final endOfHour = startOfHour.add(const Duration(hours: 1));

      final passengerSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('routeId', isEqualTo: routeId)
          .where('status', whereIn: ['booked', 'active'])
          .where('departureTime', isGreaterThanOrEqualTo: startOfHour)
          .where('departureTime', isLessThan: endOfHour)
          .get();

      return passengerSnapshot.docs.length;
    } catch (e) {
      print('Error getting passenger count: $e');
      return 0;
    }
  }
}