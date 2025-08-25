import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title "LIGN"
              Text(
                'LIGN',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40),
              // Placeholder for form fields
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(height: 8, color: Colors.black), // Placeholder for field 1
                    SizedBox(height: 10),
                    Container(height: 8, color: Colors.black, width: 200), // Placeholder for field 2
                    SizedBox(height: 10),
                    Container(height: 8, color: Colors.black, width: 150), // Placeholder for field 3
                    SizedBox(height: 10),
                    Container(height: 8, color: Colors.black), // Placeholder for field 4
                    SizedBox(height: 10),
                    Container(height: 8, color: Colors.black), // Placeholder for field 5
                    SizedBox(height: 10),
                    Container(height: 8, color: Colors.black), // Placeholder for field 6
                  ],
                ),
              ),
              SizedBox(height: 40),
              // "Use SIP" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key, size: 16),
                        SizedBox(width: 8),
                        Text('Use SIP'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // "New? Sign UP" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_add, size: 16),
                        SizedBox(width: 8),
                        Text('New? Sign UP'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
