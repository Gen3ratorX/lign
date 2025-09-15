// utils/route_admin_utility.dart
import 'package:flutter/material.dart';
import 'firebase_route_initializer.dart';


class RouteAdminUtility extends StatefulWidget {
  const RouteAdminUtility({Key? key}) : super(key: key);

  @override
  _RouteAdminUtilityState createState() => _RouteAdminUtilityState();
}

class _RouteAdminUtilityState extends State<RouteAdminUtility> {
  bool isLoading = false;
  String? statusMessage;
  Map<String, dynamic> statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() async {
    setState(() => isLoading = true);

    try {
      final stats = await FirebaseRouteInitializer.getRouteStatistics();
      setState(() {
        statistics = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = 'Error loading statistics: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Administration'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Message
            if (statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  statusMessage!,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontFamily: 'Jost',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (statistics.isNotEmpty) ...[
                      _buildStatRow('Total Routes', '${statistics['totalRoutes'] ?? 0}'),
                      _buildStatRow('To University', '${statistics['toUniversityRoutes'] ?? 0}'),
                      _buildStatRow('From University', '${statistics['fromUniversityRoutes'] ?? 0}'),
                      _buildStatRow('Active Routes', '${statistics['activeRoutes'] ?? 0}'),
                      _buildStatRow('Unique Origins', '${statistics['uniqueOrigins'] ?? 0}'),
                      _buildStatRow('Total Stops', '${statistics['totalStops'] ?? 0}'),
                    ] else
                      const Text(
                        'No route data available',
                        style: TextStyle(fontFamily: 'Jost'),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Administration Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Jost',
              ),
            ),
            const SizedBox(height: 16),

            // Initialize Routes Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _initializeRoutes,
              icon: const Icon(Icons.add_road),
              label: const Text(
                'Initialize GCTU Routes',
                style: TextStyle(fontFamily: 'Jost'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Update Routes Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _updateRoutes,
              icon: const Icon(Icons.update),
              label: const Text(
                'Update All Routes',
                style: TextStyle(fontFamily: 'Jost'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Refresh Statistics Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Refresh Statistics',
                style: TextStyle(fontFamily: 'Jost'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _showDeleteConfirmation,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'Delete All Routes',
                      style: TextStyle(fontFamily: 'Jost'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Processing...',
                      style: TextStyle(fontFamily: 'Jost'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Jost'),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
        ],
      ),
    );
  }

  void _initializeRoutes() async {
    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      await FirebaseRouteInitializer.initializeGCTURoutes();
      setState(() {
        statusMessage = 'Successfully initialized GCTU routes!';
        isLoading = false;
      });
      _loadStatistics();
    } catch (e) {
      setState(() {
        statusMessage = 'Error initializing routes: $e';
        isLoading = false;
      });
    }
  }

  void _updateRoutes() async {
    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      await FirebaseRouteInitializer.updateAllRoutes();
      setState(() {
        statusMessage = 'Successfully updated all routes!';
        isLoading = false;
      });
      _loadStatistics();
    } catch (e) {
      setState(() {
        statusMessage = 'Error updating routes: $e';
        isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete All Routes',
          style: TextStyle(fontFamily: 'Jost'),
        ),
        content: const Text(
          'Are you sure you want to delete ALL routes? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Jost'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Jost'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllRoutes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Jost',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAllRoutes() async {
    setState(() {
      isLoading = true;
      statusMessage = null;
    });

    try {
      await FirebaseRouteInitializer.deleteAllRoutes();
      setState(() {
        statusMessage = 'Successfully deleted all routes!';
        isLoading = false;
      });
      _loadStatistics();
    } catch (e) {
      setState(() {
        statusMessage = 'Error deleting routes: $e';
        isLoading = false;
      });
    }
  }
}