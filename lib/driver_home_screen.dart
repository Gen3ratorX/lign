import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'driver_service.dart';
import 'driver_model.dart';
import 'driver_tracking_screen.dart';
import 'driver_route_selection_screen.dart';
import 'dart:async';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final DriverService _driverService = DriverService();
  Driver? currentDriver;
  Map<String, dynamic>? nextTrip;
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<Driver?>? _driverSubscription;
  bool hasRoutesToday = false; // Added to track route selection status

  @override
  void initState() {
    super.initState();
    _checkDriverProfile();
    _setupSystemUI();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    super.dispose();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _checkRouteSelection() async {
    try {
      final hasRoutes = await _driverService.hasRoutesForToday();
      if (mounted) {
        setState(() {
          hasRoutesToday = hasRoutes;
        });
        // Only navigate to route selection if no routes are selected
        if (!hasRoutes) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverRouteSelectionScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking route selection: $e');
      if (mounted) {
        _showErrorSnackBar('Error checking routes: $e');
      }
    }
  }

  void _checkDriverProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Check if driver profile exists
      final hasProfile = await _driverService.hasDriverProfile();

      if (!hasProfile) {
        // Redirect to profile setup
        if (mounted) {
          context.go('/driver_profile_setup');
        }
        return;
      }

      // Start listening to driver data
      _listenToDriverData();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
        _showErrorSnackBar('Error checking profile: $e');
      }
    }
  }

  void _listenToDriverData() {
    _driverSubscription = _driverService.getCurrentDriverStream().listen(
          (driver) async {
        if (mounted) {
          setState(() {
            currentDriver = driver;
            isLoading = false;
          });

          if (driver != null) {
            _loadNextTrip();
            _checkRouteSelection(); // Moved here to ensure driver data is loaded first
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = error.toString();
          });
          _showErrorSnackBar('Error loading driver data: $error');
        }
      },
    );
  }

  void _loadNextTrip() async {
    try {
      final trip = await _driverService.getNextTripFromSelectedRoutes(); // Updated to use enhanced method
      if (mounted) {
        setState(() {
          nextTrip = trip;
        });
      }
    } catch (e) {
      print('Error loading next trip: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading driver data...', style: TextStyle(fontFamily: 'Jost')),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load driver data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Jost',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Jost',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkDriverProfile,
              child: const Text('Retry', style: TextStyle(fontFamily: 'Jost')),
            ),
          ],
        ),
      );
    }

    if (currentDriver == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Driver Profile Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Jost',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/driver_profile_setup'),
              child: const Text('Setup Profile', style: TextStyle(fontFamily: 'Jost')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _checkDriverProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (nextTrip != null) ...[
              _buildNextTripCard(),
              const SizedBox(height: 24),
            ],
            _buildMenuOptions(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: _showDriverMenu,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          currentDriver?.formattedRating ?? '4.5',
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            _showComingSoon('Notifications');
          },
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
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
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
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isOnDuty = currentDriver?.isOnDuty ?? false;
    final statusColor = isOnDuty ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentDriver?.busNumber ?? 'BS204',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capacity: ${currentDriver?.capacity ?? 15}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRoutesToday ? 'Routes Selected' : 'No Routes Selected',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasRoutesToday ? Colors.green : Colors.red,
                        fontFamily: 'Jost',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : _toggleDutyStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnDuty ? Colors.red : Colors.green,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isOnDuty ? 'End Shift' : 'Start Shift',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _navigateToTracking();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextTripCard() {
    if (nextTrip == null) return const SizedBox.shrink();

    final departureTime = nextTrip!['departureTime'] as DateTime;
    final timeString = '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF4A90E2)),
              SizedBox(width: 8),
              Text(
                'Next Trip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Jost',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${nextTrip!['route'] ?? 'Unknown Route'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Departure: $timeString',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Students Booked: ${nextTrip!['passengerCount'] ?? 0}/${nextTrip!['capacity'] ?? 15}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Jost',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  _navigateToTracking();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Start Trip',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildMenuOptions() {
    final menuItems = [
      {'title': 'Select Routes', 'icon': Icons.route, 'route': '/driver_route_selection'}, // Added route selection
      {'title': 'My Trips', 'icon': Icons.directions_bus, 'route': '/driver_trips'},
      {'title': 'Active Trips', 'icon': Icons.track_changes, 'route': '/active_trips'},
      {'title': 'Reports/Logs', 'icon': Icons.description, 'route': '/driver_reports'},
      {'title': 'Help & Support', 'icon': Icons.help_outline, 'route': '/driver_support'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Jost',
          ),
        ),
        const SizedBox(height: 16),
        ...menuItems.map((item) => _buildMenuItem(
          title: item['title'] as String,
          icon: item['icon'] as IconData,
          route: item['route'] as String,
        )),
      ],
    );
  }

  Widget _buildMenuItem({required String title, required IconData icon, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleMenuNavigation(route, title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickActionButton(
                icon: Icons.route,
                label: 'Select Routes', // Added route selection quick action
                color: const Color(0xFF4A90E2),
                onTap: _navigateToRouteSelection,
              ),
              _buildQuickActionButton(
                icon: Icons.emergency,
                label: 'Emergency',
                color: Colors.red,
                onTap: _handleEmergency,
              ),
              _buildQuickActionButton(
                icon: Icons.phone,
                label: 'Support',
                color: Colors.blue,
                onTap: _contactSupport,
              ),
              _buildQuickActionButton(
                icon: Icons.logout,
                label: 'Logout',
                color: Colors.grey,
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'Jost',
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _navigateToTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverTrackingScreen(),
      ),
    );
  }

  void _navigateToRouteSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverRouteSelectionScreen(),
      ),
    );
  }

  void _showComingSoon(String feature) {
    _showErrorSnackBar('$feature - Coming Soon');
  }

  void _toggleDutyStatus() async {
    if (currentDriver == null || isLoading) return;

    setState(() => isLoading = true);

    try {
      if (currentDriver!.isOnDuty) {
        await _driverService.endShift();
        _showSuccessSnackBar('Shift ended successfully');
      } else {
        if (!hasRoutesToday) {
          setState(() => isLoading = false);
          _showErrorSnackBar('Please select routes before starting shift');
          _navigateToRouteSelection();
          return;
        }
        await _driverService.startShift();
        _showSuccessSnackBar('Shift started successfully');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showDriverMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Settings', style: TextStyle(fontFamily: 'Jost')),
              onTap: () {
                Navigator.pop(context);
                context.push('/driver_profile_setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Select Routes', style: TextStyle(fontFamily: 'Jost')), // Added to bottom sheet
              onTap: () {
                Navigator.pop(context);
                _navigateToRouteSelection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Settings', style: TextStyle(fontFamily: 'Jost')),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('App Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(fontFamily: 'Jost', color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  void _handleMenuNavigation(String route, String title) {
    if (route == '/driver_route_selection') {
      _navigateToRouteSelection();
    } else {
      _showComingSoon(title);
    }
  }

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert', style: TextStyle(fontFamily: 'Jost')),
        content: const Text(
          'Are you in an emergency situation? This will alert support and nearby authorities.',
          style: TextStyle(fontFamily: 'Jost'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Jost')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Emergency alert sent!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert', style: TextStyle(color: Colors.white, fontFamily: 'Jost')),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    _showComingSoon('Support Contact');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontFamily: 'Jost')),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Jost'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Jost')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.mounted) {
                context.go('/sip_sign_in');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontFamily: 'Jost')),
          ),
        ],
      ),
    );
  }
}