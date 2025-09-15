import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Calculate letter spacing based on screen width
              LayoutBuilder(
                builder: (context, constraints) {
                  final text = 'LIGN';
                  final textWidth = _calculateTextWidth(
                    text,
                    TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 18, // No additional spacing for calculation
                    ),
                  );

                  final availableWidth = constraints.maxWidth;
                  final spacing = (availableWidth - textWidth) / (text.length - 1);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'LIGN',
                        style: TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: spacing,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/logo.json',
                    fit: BoxFit.fill,
                    repeat: true,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      context.go('/sip_sign_in');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.login, color: Colors.black, size: 24),
                          SizedBox(width: 16),
                          Text(
                            'Use SIP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      context.go('/sign_up');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.black, size: 24),
                          SizedBox(width: 16),
                          Text(
                            'New? Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to calculate text width
  static double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }
}