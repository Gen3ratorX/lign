import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Firestore
import 'package:go_router/go_router.dart';

// Import your FirebaseRouteInitializer (adjust the path to match your project structure)
import 'firebase_route_initializer.dart'; // Ensure this points to your FirebaseRouteInitializer file

// Auth Screens
import 'auth_screens/splash_screen.dart';
import 'auth_screens/onboarding_screen.dart';
import 'auth_screens/sip_sign_in_screen.dart';
import 'auth_screens/sign_up_screen.dart';
import 'auth_screens/selection_screen.dart';
import 'auth_screens/welcome_screen.dart';
import 'auth_screens/forgot_password.dart';

// Main App Screens
import 'commuter_home_screen.dart';
import 'driver_home_screen.dart';
import 'admin_dashboard_screen.dart';

// Driver Screens
import 'driver_tracking_screen.dart';
import 'driver_profile_setup_screen.dart';
import 'driver_route_selection_screen.dart';
import 'gctu_route_selection_screen.dart';

// Existing Commuter Screens
import 'profile_settings_screen.dart';
import 'basic_user_info_screen.dart';
import 'my_trips_screen.dart';
import 'schedules_screen.dart';
import 'route_details_screen.dart';
import 'incoming_screen.dart';
import 'booking_screen.dart';
import 'tickets_screen.dart';
import 'trip_tracking_screen.dart';

// Profile Completion System
import 'profile_completion_wrapper.dart';

import 'route_admin_utility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase initialization

  // Add route initialization here
  try {
    await FirebaseRouteInitializer.initializeGCTURoutes();
    print('Routes initialized successfully');
  } catch (e) {
    print('Error initializing routes: $e');
  }

  runApp(const MyApp());
}

// Rest of your main.dart remains unchanged
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      // Auth Flow Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sip_sign_in',
        builder: (context, state) => const SipSignInScreen(),
      ),
      GoRoute(
        path: '/sign_up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/selection',
        builder: (context, state) => const SelectionScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Profile Completion Flow
      GoRoute(
        path: '/profile_wrapper',
        builder: (context, state) => const ProfileCompletionWrapper(),
      ),
      GoRoute(
        path: '/complete_profile',
        builder: (context, state) => const BasicUserInfoScreen(isFirstTime: true),
      ),

      // Main App Routes
      GoRoute(
        path: '/commuter_home',
        builder: (context, state) => const CommuterHomeScreen(),
      ),
      GoRoute(
        path: '/driver_home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Driver-Specific Routes
      GoRoute(
        path: '/driver_profile_setup',
        builder: (context, state) => const DriverProfileSetupScreen(),
      ),
      GoRoute(
        path: '/driver_tracking',
        builder: (context, state) => const DriverTrackingScreen(),
      ),
      GoRoute(
        path: '/driver_routes',
        builder: (context, state) => const DriverRouteSelectionScreen(),
      ),
      GoRoute(
        path: '/gctu_routes',
        builder: (context, state) => const GCTURouteSelectionScreen(),
      ),
      GoRoute(
        path: '/driver_trips',
        builder: (context, state) => const DriverTripsScreen(),
      ),
      GoRoute(
        path: '/active_trips',
        builder: (context, state) => const ActiveTripsScreen(),
      ),
      GoRoute(
        path: '/driver_reports',
        builder: (context, state) => const DriverReportsScreen(),
      ),
      GoRoute(
        path: '/driver_support',
        builder: (context, state) => const DriverSupportScreen(),
      ),

      // Profile & Settings Routes
      GoRoute(
        path: '/profile_settings',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/basic_user_info',
        builder: (context, state) => const BasicUserInfoScreen(isFirstTime: false),
      ),

      // Trip Management Routes
      GoRoute(
        path: '/my_trips',
        builder: (context, state) => const MyTripsScreen(),
      ),
      GoRoute(
        path: '/schedules',
        builder: (context, state) => const SchedulesScreen(),
      ),
      GoRoute(
        path: '/incoming',
        builder: (context, state) => const IncomingScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingScreen(),
      ),

      // Route Details with Parameters
      GoRoute(
        path: '/route_details/:routeId',
        builder: (context, state) => RouteDetailsScreen(
          routeId: state.pathParameters['routeId'],
        ),
      ),
      GoRoute(
        path: '/route_details',
        builder: (context, state) => const RouteDetailsScreen(),
      ),

      // Trip Tracking with Parameters
      GoRoute(
        path: '/trip_tracking/:tripId',
        builder: (context, state) => TripTrackingScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),

      // Tickets & Payment Routes
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketsScreen(),
      ),

      // Route Administration (for admin use)
      GoRoute(
        path: '/route_admin',
        builder: (context, state) => const RouteAdminUtility(),
      ),

      // Additional Settings Routes
      GoRoute(
        path: '/travel_preferences',
        builder: (context, state) => const TravelPreferencesScreen(),
      ),
      GoRoute(
        path: '/payment_settings',
        builder: (context, state) => const PaymentSettingsScreen(),
      ),
      GoRoute(
        path: '/support_settings',
        builder: (context, state) => const SupportSettingsScreen(),
      ),
      GoRoute(
        path: '/account_controls',
        builder: (context, state) => const AccountControlsScreen(),
      ),
      GoRoute(
        path: '/transaction_history',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RideFlow - Your Ride Partner',
      theme: _buildLightTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Jost',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        brightness: Brightness.light,
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        surface: Colors.grey.shade50,
        background: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          fontFamily: 'Jost',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          fontFamily: 'Jost',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamily: 'Jost',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Jost',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Jost',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontFamily: 'Jost',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontFamily: 'Jost',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.all(20),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontFamily: 'Jost',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Jost',
        ),
      ),
    );
  }
}

// ============================================================================
// DRIVER-SPECIFIC PLACEHOLDER SCREENS
// ============================================================================

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Driver Trips History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Jost'),
            ),
            SizedBox(height: 8),
            Text(
              'View your completed and upcoming trips',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Jost'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 18, fontFamily: 'Jost', color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveTripsScreen extends StatelessWidget {
  const ActiveTripsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trips'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Active Trips Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Jost'),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your currently active routes and passengers',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Jost'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 18, fontFamily: 'Jost', color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverReportsScreen extends StatelessWidget {
  const DriverReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Driver Reports & Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Jost'),
            ),
            SizedBox(height: 8),
            Text(
              'View your performance reports and trip logs',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Jost'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 18, fontFamily: 'Jost', color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverSupportScreen extends StatelessWidget {
  const DriverSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Driver Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Jost'),
            ),
            SizedBox(height: 8),
            Text(
              'Get help with the driver app and contact support',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Jost'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 18, fontFamily: 'Jost', color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXISTING PLACEHOLDER SCREENS
// ============================================================================

class TravelPreferencesScreen extends StatelessWidget {
  const TravelPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Travel Preferences\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Jost'),
        ),
      ),
    );
  }
}

class PaymentSettingsScreen extends StatelessWidget {
  const PaymentSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Payment Settings\n(Wallet System Active)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Jost'),
        ),
      ),
    );
  }
}

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Support & Settings\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Jost'),
        ),
      ),
    );
  }
}

class AccountControlsScreen extends StatelessWidget {
  const AccountControlsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Controls'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Account Controls\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Jost'),
        ),
      ),
    );
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Transaction History\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Jost'),
        ),
      ),
    );
  }
}