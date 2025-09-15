import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'gctu_route_service.dart';

class GCTURouteSelectionScreen extends StatefulWidget {
  const GCTURouteSelectionScreen({Key? key}) : super(key: key);

  @override
  _GCTURouteSelectionScreenState createState() => _GCTURouteSelectionScreenState();
}

class _GCTURouteSelectionScreenState extends State<GCTURouteSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GCTURouteService _routeService = GCTURouteService();

  List<Map<String, dynamic>> toUniversityRoutes = [];
  List<Map<String, dynamic>> fromUniversityRoutes = [];
  bool isLoading = true;
  String searchQuery = '';

  final List<String> popularOrigins = ['Kasoa', 'Teshie', 'Tema', 'Nsawam'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRoutes();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async { // Changed return type to Future<void>
    setState(() => isLoading = true);

    try {
      final toRoutes = await _routeService.getToUniversityRoutes();
      final fromRoutes = await _routeService.getFromUniversityRoutes();

      if (mounted) {
        setState(() {
          toUniversityRoutes = toRoutes;
          fromUniversityRoutes = fromRoutes;
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

  void _searchRoutes(String query) async {
    if (query.trim().isEmpty) {
      _loadRoutes();
      return;
    }

    setState(() => isLoading = true);

    try {
      final results = await _routeService.searchRoutes(query);

      if (mounted) {
        setState(() {
          toUniversityRoutes = results.where((r) => r['direction'] == 'to_university').toList();
          fromUniversityRoutes = results.where((r) => r['direction'] == 'from_university').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching routes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('GCTU Routes'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4A90E2),
          labelColor: const Color(0xFF4A90E2),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontFamily: 'Jost', fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'To GCTU'),
            Tab(text: 'From GCTU'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
                _searchRoutes(value);
              },
              decoration: InputDecoration(
                hintText: 'Search routes by origin or destination...',
                hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Jost'),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              style: const TextStyle(fontFamily: 'Jost'),
            ),
          ),

          // Popular Origins (only show when not searching)
          if (searchQuery.isEmpty) _buildPopularOrigins(),

          // Routes TabView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRouteList(toUniversityRoutes, 'to_university'),
                _buildRouteList(fromUniversityRoutes, 'from_university'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularOrigins() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Origins',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: popularOrigins.map((origin) => _buildOriginChip(origin)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginChip(String origin) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          origin,
          style: const TextStyle(fontFamily: 'Jost'),
        ),
        onSelected: (selected) {
          if (selected) {
            _searchRoutes(origin);
          }
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF4A90E2).withOpacity(0.2),
        checkmarkColor: const Color(0xFF4A90E2),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildRouteList(List<Map<String, dynamic>> routes, String direction) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading routes...', style: TextStyle(fontFamily: 'Jost')),
          ],
        ),
      );
    }

    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No routes available'
                  : 'No routes found for "$searchQuery"',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Jost',
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => searchQuery = '');
                  _loadRoutes();
                },
                child: const Text('Clear Search', style: TextStyle(fontFamily: 'Jost')),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoutes, // Now correctly typed as Future<void>
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return _buildRouteCard(route, direction);
        },
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, String direction) {
    final schedules = List<Map<String, dynamic>>.from(route['schedules'] ?? []);
    final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
    final pickupStops = stops.where((stop) => stop['isPickupPoint'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showRouteDetails(route),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route['routeCode'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90E2),
                              fontFamily: 'Jost',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route['from']} → ${route['to']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Jost',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GHS ${route['fare']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route Info
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time,
                      '${route['estimatedDuration'] ?? 0} min',
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.straighten,
                      '${route['distance']?.toStringAsFixed(1) ?? '0'} km',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.location_on,
                      '$pickupStops stops',
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Schedules
                if (schedules.isNotEmpty) ...[
                  Text(
                    'Departure Times',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: schedules.map((schedule) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          schedule['departureTime'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A90E2),
                            fontFamily: 'Jost',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectRoute(route),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Select Route',
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Jost',
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRouteDetailsModal(route),
    );
  }

  Widget _buildRouteDetailsModal(Map<String, dynamic> route) {
    final stops = List<Map<String, dynamic>>.from(route['stops'] ?? []);
    final schedules = List<Map<String, dynamic>>.from(route['schedules'] ?? []);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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

          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Route Details',
                  style: TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['routeCode'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90E2),
                            fontFamily: 'Jost',
                          ),
                        ),
                        const SizedBox(height: 4),
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
                            Text(
                              'Fare: GHS ${route['fare']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Jost',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Duration: ${route['estimatedDuration'] ?? 0} min',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Jost',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Schedules Section
                  if (schedules.isNotEmpty) ...[
                    const Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...schedules.map((schedule) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: Color(0xFF4A90E2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${schedule['departureTime']} - ${schedule['arrivalTime']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Jost',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              schedule['frequency'] ?? 'Daily',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                                fontFamily: 'Jost',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Stops Section
                  const Text(
                    'Route Stops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...stops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    final isPickup = stop['isPickupPoint'] == true;
                    final isLast = index == stops.length - 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Stop indicator
                          Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isPickup ? const Color(0xFF4A90E2) : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Stop details
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPickup ? Colors.blue[50] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPickup ? Colors.blue[200]! : Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stop['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isPickup ? Colors.blue[800] : Colors.grey[700],
                                            fontFamily: 'Jost',
                                          ),
                                        ),
                                      ),
                                      if (isPickup)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Pickup',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (stop['estimatedTime'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'ETA: +${stop['estimatedTime']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Jost',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _selectRoute(route);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book This Route',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectRoute(Map<String, dynamic> route) {
    // Navigate to booking screen with selected route
    context.push('/route_details/${route['id']}');
  }
}