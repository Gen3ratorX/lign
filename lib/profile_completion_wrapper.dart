import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'basic_user_info_screen.dart';
import 'commuter_home_screen.dart';
import 'auth_screens/sip_sign_in_screen.dart';

class ProfileCompletionWrapper extends StatelessWidget {
  const ProfileCompletionWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const SipSignInScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const BasicUserInfoScreen(isFirstTime: true);
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final profileCompleted = userData['profileCompleted'] ?? false;

            if (!profileCompleted) {
              return const BasicUserInfoScreen(isFirstTime: true);
            }

            return const CommuterHomeScreen();
          },
        );
      },
    );
  }
}