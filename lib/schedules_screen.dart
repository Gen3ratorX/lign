// screens/schedules_screen.dart - Updated with GCTU Routes Integration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'gctu_route_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({Key? key}) : super(key: key);

  @override
  _SchedulesScreenState createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GCTURouteService _routeService = GCTURouteService();

  List<Map<String, dynamic>> toUniversityRoutes = [];
  List<Map<String, dynamic>> fromUniversityRoutes = [];
  List<Map<String, dynamic>> nearbyStops = [];
  List<Map<String, dynamic>> allStops = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGCTURoutes();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void>  _loadGCTURoutes() async {
    setState(() => isLoading = true);

    try {
      final toRoutes = await _routeService.getToUniversityRoutes();
      final fromRoutes = await _routeService.getFromUniversityRoutes();

      // Generate nearby stops from routes
      final stops = <Map<String, dynamic>>[];
      for (var route in [...toRoutes, ...fromRoutes]) {
        final routeStops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
        for (var stop in routeStops) {
          if (stop['isPickupPoint'] == true) {
            stops.add({
              'name': stop['name'],
              'distance': '${(0.5 + (stops.length * 0.3)).toStringAsFixed(1)} km',
              'nextBus': '${5 + (stops.length * 3)} mins',
              'routes': [route['routeCode']],
            });
          }
        }
      }

      setState(() {
        toUniversityRoutes = toRoutes;
        fromUniversityRoutes = fromRoutes;
        nearbyStops = stops.take(10).toList();
        allStops = _generateAllStops(toRoutes + fromRoutes);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading routes: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _generateAllStops(List<Map<String, dynamic>> routes) {
    final stopMap = <String, Map<String, dynamic>>{};

    for (var route in routes) {
      final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
      for (var stop in stops) {
        final stopName = stop['name'] as String;
        if (!stopMap.containsKey(stopName)) {
          stopMap[stopName] = {
            'name': stopName,
            'routes': <String>[],
            'facilities': <String>['Shelter', 'Information Board'],
          };
        }
        if (!stopMap[stopName]!['routes'].contains(route['routeCode'])) {
          stopMap[stopName]!['routes'].add(route['routeCode']);
        }
      }
    }

    return stopMap.values.toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    "GCTU Schedules",
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
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Input
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Jost',
                ),
                decoration: InputDecoration(
                  hintText: "Search by origin (Kasoa, Teshie, Tema, Nsawam)",
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontFamily: 'Jost',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) => _onSearchChanged(value),
              ),
            ),

            // Tab Buttons
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildTabButton("To GCTU", 0, _tabController.index == 0),
                  const SizedBox(width: 1),
                  _buildTabButton("From GCTU", 1, _tabController.index == 1),
                  const SizedBox(width: 1),
                  _buildTabButton("Stops", 2, _tabController.index == 2),
                ],
              ),
            ),

            // Browse All Routes Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/gctu_routes'),
                icon: const Icon(Icons.explore, color: Colors.white),
                label: const Text(
                  "Browse All GCTU Routes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoutesTab(toUniversityRoutes, 'to_university'),
                  _buildRoutesTab(fromUniversityRoutes, 'from_university'),
                  _buildStopsTab(),
                ],
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
                      GestureDetector(
                        onTap: () => context.push('/tickets'),
                        child: const Icon(
                          Icons.directions_bus_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/commuter_home'),
                        child: const Icon(
                          Icons.home_outlined,
                          color: Color(0xFF4A90E2),
                          size: 28,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile_settings'),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 26,
                        ),
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

  Widget _buildTabButton(String text, int index, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Jost',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutesTab(List<Map<String, dynamic>> routes, String direction) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (routes.isEmpty) {
      return _buildEmptyState(
          "No routes available",
          direction == 'to_university'
              ? "Routes to GCTU will appear here"
              : "Return routes from GCTU will appear here"
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGCTURoutes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return _buildGCTURouteCard(route);
        },
      ),
    );
  }

  Widget _buildStopsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: allStops.length,
      itemBuilder: (context, index) {
        final stop = allStops[index];
        return _buildStopCard(stop);
      },
    );
  }

  Widget _buildGCTURouteCard(Map<String, dynamic> route) {
    final schedules = List<Map<String, dynamic>>.from(route['schedules'] ?? []);
    final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
    final pickupStops = stops.where((stop) => stop['isPickupPoint'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Text(
                'GHS ${route['fare']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'Jost',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${route['from']} → ${route['to']}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                "${route['estimatedDuration'] ?? 0} min",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Jost',
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                "$pickupStops stops",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Jost',
                ),
              ),
              const Spacer(),
              Text(
                "${route['distance']?.toStringAsFixed(1) ?? '0'} km",
                style: TextStyle(
                  fontSize: 12,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Jost',
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: schedules.map((schedule) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule['departureTime'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                      fontFamily: 'Jost',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _selectRoute(route),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Book This Route',
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
      ),
    );
  }

  Widget _buildStopCard(Map<String, dynamic> stop) {
    final routes = List<String>.from(stop['routes'] ?? []);
    final facilities = List<String>.from(stop['facilities'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Expanded(
                child: Text(
                  stop['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${routes.length} Routes",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ],
          ),
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: routes.map((route) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    route,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4A90E2),
                      fontFamily: 'Jost',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (facilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: facilities.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    facility,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontFamily: 'Jost',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      _loadGCTURoutes();
      return;
    }

    setState(() => isLoading = true);

    try {
      final results = await _routeService.searchRoutes(value);

      setState(() {
        toUniversityRoutes = results.where((r) => r['direction'] == 'to_university').toList();
        fromUniversityRoutes = results.where((r) => r['direction'] == 'from_university').toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _selectRoute(Map<String, dynamic> route) {
    context.push('/route_details/${route['id']}');
  }
}