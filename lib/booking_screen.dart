import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'gctu_route_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final GCTURouteService _routeService = GCTURouteService();

  String selectedRoute = '';
  List<Map<String, dynamic>> availableRoutes = [];
  Map<String, dynamic>? selectedSchedule;
  bool isLoading = false;
  bool isGCTUMode = true;

  // GCTU popular origins
  final List<String> gctuOrigins = ['Kasoa', 'Teshie', 'Tema', 'Nsawam', 'Circle', 'Ablekuma'];

  @override
  void initState() {
    super.initState();
    _toController.text = 'GCTU Campus';
    _loadWeeklySchedules(); // Load weekly schedules by default
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _loadWeeklySchedules() async {
    setState(() => isLoading = true);

    try {
      // Calculate the start and end of the current week (Monday to Sunday)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final startOfWeek = Timestamp.fromDate(DateTime(monday.year, monday.month, monday.day));
      final endOfWeek = Timestamp.fromDate(DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59));

      // Fetch schedules for the week
      final snapshot = await FirebaseFirestore.instance
          .collection('driver_schedules')
          .where('date', isGreaterThanOrEqualTo: startOfWeek)
          .where('date', isLessThanOrEqualTo: endOfWeek)
          .get();

      final schedules = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Fetch driver data for each schedule
      final routesWithDriverData = await Future.wait(schedules.map((schedule) async {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(schedule['driverId'])
            .get();
        final driverData = driverDoc.exists ? driverDoc.data() : {};
        return {
          ...schedule,
          'driverName': driverData?['name'] ?? 'Unknown Driver',
          'busNumber': driverData?['busNumber'] ?? 'Unknown',
          'capacity': driverData?['capacity'] ?? 35,
        };
      }));

      setState(() {
        availableRoutes = routesWithDriverData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading weekly schedules: $e')),
      );
    }
  }

  void _loadGCTURoutes() async {
    setState(() => isLoading = true);

    try {
      final routes = await _routeService.getToUniversityRoutes();
      // Fetch driver data for each route
      final routesWithDriverData = await Future.wait(routes.map((route) async {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(route['driverId'])
            .get();
        final driverData = driverDoc.exists ? driverDoc.data() : {};
        return {
          ...route,
          'driverName': driverData?['name'] ?? 'Unknown Driver',
          'busNumber': driverData?['busNumber'] ?? 'Unknown',
          'capacity': driverData?['capacity'] ?? 35,
        };
      }));

      setState(() {
        availableRoutes = routesWithDriverData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading GCTU routes: $e')),
      );
    }
  }

  void _loadCustomRoutes() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();

      final routes = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Fetch driver data for each route
      final routesWithDriverData = await Future.wait(routes.map((route) async {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(route['driverId'])
            .get();
        final driverData = driverDoc.exists ? driverDoc.data() : {};
        return {
          ...route,
          'driverName': driverData?['name'] ?? 'Unknown Driver',
          'busNumber': driverData?['busNumber'] ?? 'Unknown',
          'capacity': driverData?['capacity'] ?? 35,
        };
      }));

      setState(() {
        availableRoutes = routesWithDriverData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading routes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isGCTUMode ? 'Book Trip to GCTU' : 'Book a Ride',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Jost',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isGCTUMode ? Icons.school : Icons.directions_bus,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                isGCTUMode = !isGCTUMode;
                availableRoutes.clear();
                selectedRoute = '';
                if (isGCTUMode) {
                  _toController.text = 'GCTU Campus';
                  _fromController.clear();
                  _loadGCTURoutes();
                } else {
                  _toController.clear();
                  _fromController.clear();
                  _loadCustomRoutes();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isGCTUMode = true;
                        availableRoutes.clear();
                        selectedRoute = '';
                        _toController.text = 'GCTU Campus';
                        _fromController.clear();
                        _loadGCTURoutes();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isGCTUMode ? const Color(0xFF667eea) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GCTU Routes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isGCTUMode ? Colors.white : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isGCTUMode = false;
                        availableRoutes.clear();
                        selectedRoute = '';
                        _toController.clear();
                        _fromController.clear();
                        _loadCustomRoutes();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isGCTUMode ? const Color(0xFF667eea) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Other Routes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isGCTUMode ? Colors.white : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isGCTUMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select your origin:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: gctuOrigins.map((origin) => _buildOriginChip(origin)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildLocationInput(
                  controller: _fromController,
                  hint: isGCTUMode ? 'Select origin above or type here' : 'From',
                  icon: Icons.radio_button_checked,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildLocationInput(
                  controller: _toController,
                  hint: isGCTUMode ? 'GCTU Campus (fixed)' : 'To',
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  enabled: !isGCTUMode,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _searchRoutes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLoading ? 'Searching...' : (isGCTUMode ? 'Find GCTU Routes' : 'Search Routes'),
                      style: const TextStyle(
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
          ),
          if (availableRoutes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGCTUMode ? 'GCTU Routes' : 'Available Routes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Jost',
                    ),
                  ),
                  Text(
                    '${availableRoutes.length} found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableRoutes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: availableRoutes.length,
              itemBuilder: (context, index) {
                final route = availableRoutes[index];
                return isGCTUMode
                    ? _buildGCTURouteCard(route)
                    : _buildRouteCard(route);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginChip(String origin) {
    final isSelected = _fromController.text == origin;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          origin,
          style: TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF667eea),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _fromController.text = selected ? origin : '';
            selectedRoute = '';
          });
          if (selected) {
            _searchGCTURoutes(origin);
          }
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF667eea),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Jost',
          color: enabled ? Colors.black : Colors.grey[500],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Jost',
          ),
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (value) {
          setState(() {
            selectedRoute = '';
          });
        },
      ),
    );
  }

  Widget _buildGCTURouteCard(Map<String, dynamic> schedule) {
    final isSelected = selectedRoute == schedule['id'];
    final schedules = List<Map<String, dynamic>>.from(schedule['schedules'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF667eea).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectRoute(schedule),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      schedule['busNumber'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GHS ${schedule['fare']?.toStringAsFixed(2) ?? '8.00'}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule['from'] ?? 'Origin',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 2,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 2,
                    color: Colors.grey[400],
                  ),
                  const Expanded(
                    child: Text(
                      'GCTU Campus',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Driver: ${schedule['driverName'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Date: ${(schedule['date'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule['capacity'] ?? 35} seats',
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
                  'Available Times:',
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
                  children: schedules.take(3).map((timeSlot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeSlot['departureTime'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667eea),
                          fontFamily: 'Jost',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (isSelected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _bookGCTUTrip(schedule),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book GCTU Trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isSelected = selectedRoute == route['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF667eea).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectRoute(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      route['busNumber'] ?? route['routeCode'] ?? 'BS204',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'On time',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Jost',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route['from'] ?? 'From',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 2,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 2,
                    color: Colors.grey[400],
                  ),
                  Expanded(
                    child: Text(
                      route['to'] ?? 'To',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Driver: ${route['driverName'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Departure: ${route['departureTime'] ?? '10:30 AM'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${route['availableSeats'] ?? route['capacity'] ?? 12} seats',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _bookTrip(route),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book This Trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isGCTUMode ? Icons.school : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isGCTUMode ? 'No GCTU routes available' : 'No routes found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGCTUMode
                ? 'Try selecting a different origin or check back later'
                : 'Try searching for a different destination',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Jost',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _searchRoutes() async {
    if (isGCTUMode) {
      if (_fromController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter your origin location')),
        );
        return;
      }
      _searchGCTURoutes(_fromController.text);
    } else {
      if (_fromController.text.isEmpty || _toController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in both locations')),
        );
        return;
      }
      _searchCustomRoutes();
    }
  }

  void _searchGCTURoutes(String origin) async {
    setState(() => isLoading = true);

    try {
      final results = await _routeService.getRoutesByOrigin(origin);
      // Fetch driver data for each route
      final routesWithDriverData = await Future.wait(results.map((route) async {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(route['driverId'])
            .get();
        final driverData = driverDoc.exists ? driverDoc.data() : {};
        return {
          ...route,
          'driverName': driverData?['name'] ?? 'Unknown Driver',
          'busNumber': driverData?['busNumber'] ?? 'Unknown',
          'capacity': driverData?['capacity'] ?? 35,
        };
      }));

      setState(() {
        availableRoutes = routesWithDriverData;
        isLoading = false;
      });

      if (availableRoutes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No GCTU routes found from this location')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching GCTU routes: $e')),
      );
    }
  }

  void _searchCustomRoutes() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('from', isEqualTo: _fromController.text.trim())
          .where('to', isEqualTo: _toController.text.trim())
          .where('isActive', isEqualTo: true)
          .get();

      final routes = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Fetch driver data for each route
      final routesWithDriverData = await Future.wait(routes.map((route) async {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(route['driverId'])
            .get();
        final driverData = driverDoc.exists ? driverDoc.data() : {};
        return {
          ...route,
          'driverName': driverData?['name'] ?? 'Unknown Driver',
          'busNumber': driverData?['busNumber'] ?? 'Unknown',
          'capacity': driverData?['capacity'] ?? 12,
        };
      }));

      setState(() {
        availableRoutes = routesWithDriverData;
        isLoading = false;
      });

      if (availableRoutes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No routes found for this destination')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching routes: $e')),
      );
    }
  }

  void _selectRoute(Map<String, dynamic> route) {
    setState(() {
      selectedRoute = selectedRoute == route['id'] ? '' : route['id'];
    });
  }

  void _bookGCTUTrip(Map<String, dynamic> schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a trip')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'routeId': schedule['routeId'],
        'scheduleId': schedule['id'],
        'from': schedule['from'],
        'to': 'GCTU Campus',
        'busNumber': schedule['busNumber'] ?? 'Unknown',
        'departureTime': (schedule['schedules'] as List<dynamic>)?.first['departureTime'] ?? 'Unknown',
        'status': 'booked',
        'bookingTime': Timestamp.now(),
        'driverName': schedule['driverName'] ?? 'Unknown Driver',
        'driverId': schedule['driverId'],
        'fare': schedule['fare'] ?? 8.0,
        'date': schedule['date'],
      });

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GCTU Trip booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking GCTU trip: $e')),
      );
    }
  }

  void _bookTrip(Map<String, dynamic> route) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a trip')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'userId': user.uid,
        'routeId': route['id'],
        'from': route['from'],
        'to': route['to'],
        'busNumber': route['busNumber'] ?? route['routeCode'] ?? 'BS204',
        'departureTime': route['departureTime'] ?? '10:30 AM',
        'status': 'booked',
        'bookingTime': Timestamp.now(),
        'driverName': route['driverName'] ?? 'Unknown Driver',
        'driverId': route['driverId'],
        'fare': route['fare'] ?? 0.0,
      });

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking trip: $e')),
      );
    }
  }
}