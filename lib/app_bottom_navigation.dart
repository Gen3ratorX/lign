import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 34,
      left: 0,
      right: 0,
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
              // Tickets/Bus Tab
              GestureDetector(
                onTap: () => _onNavTap(context, 0),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: currentIndex == 0 ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: currentIndex == 0 ? Colors.black : Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Home Tab
              GestureDetector(
                onTap: () => _onNavTap(context, 1),
                child: Icon(
                  Icons.home_outlined,
                  color: currentIndex == 1 ? const Color(0xFF4A90E2) : Colors.white,
                  size: 28,
                ),
              ),

              // Profile Tab
              GestureDetector(
                onTap: () => _onNavTap(context, 2),
                child: Icon(
                  Icons.person_outline,
                  color: currentIndex == 2 ? const Color(0xFF4A90E2) : Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    // Don't navigate if already on the selected screen
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.push('/tickets');
        break;
      case 1:
        context.push('/commuter_home');
        break;
      case 2:
        context.push('/profile_settings');
        break;
    }
  }
}

// Helper method to determine current index based on route
class NavigationHelper {
  static int getCurrentIndex(String currentRoute) {
    switch (currentRoute) {
      case '/tickets':
        return 0;
      case '/commuter_home':
        return 1;
      case '/profile_settings':
        return 2;
      default:
        return 1; // Default to home
    }
  }
}