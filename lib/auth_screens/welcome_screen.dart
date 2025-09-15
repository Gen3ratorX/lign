import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final role = extra?['role'] as String?;
      if (mounted) {
        if (role == 'commuter') {
          context.go('/commuter_home');
        } else if (role == 'driver') {
          context.go('/driver_home');
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final role = extra?['role'] as String?;
    String welcomeMessage = role == 'driver' ? 'Welcome, Driver!' : 'Welcome, Commuter!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.json',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                welcomeMessage,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Getting ready for your journey...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}