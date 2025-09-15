import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  Map<String, dynamic> userProfile = {};
  double walletBalance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Load user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userProfile = userDoc.data() as Map<String, dynamic>;
          walletBalance = userProfile['walletBalance']?.toDouble() ?? 50.0;
        });
      } else {
        // Create default profile if doesn't exist
        final defaultProfile = {
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': '',
          'walletBalance': 50.0,
          'isActive': true,
          'joinedDate': Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(defaultProfile);

        setState(() {
          userProfile = defaultProfile;
          walletBalance = 50.0;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              color: Colors.white,
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
                    "Profile Settings",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Section
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Color(0xFF90EE90),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(userProfile['name'] ?? 'User'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Jost',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Name
                          Text(
                            userProfile['name'] ?? 'Omar Sheriff',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Jost',
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Email
                          Text(
                            userProfile['email'] ?? 'Omarsheriff@gmail.com',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontFamily: 'Jost',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Wallet Card - Fintech Style
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667eea),
                            Color(0xFF764ba2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Wallet Balance",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Jost',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "RideFlow",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Jost',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "GHS ${walletBalance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Jost',
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showTopUpModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF667eea),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    "Top Up",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Jost',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showTransactionHistory,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.history, size: 18),
                                  label: const Text(
                                    "History",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Jost',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settings Options
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSettingsOption(
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFF4A90E2),
                            title: "Basic User Information",
                            onTap: () => _navigateToBasicInfo(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.luggage,
                            iconColor: Colors.orange,
                            title: "Travel preferences",
                            onTap: () => _navigateToTravelPreferences(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.toggle_on,
                            iconColor: Colors.green,
                            title: "Active/Inactive Toggle",
                            onTap: () => _toggleActiveStatus(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.payment,
                            iconColor: const Color(0xFF667eea),
                            title: "Payment",
                            onTap: () => _navigateToPaymentSettings(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.history,
                            iconColor: Colors.pink,
                            title: "Travel History shortcut",
                            onTap: () => _navigateToTravelHistory(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.settings,
                            iconColor: Colors.orange,
                            title: "Support and settings",
                            onTap: () => _navigateToSupport(),
                          ),

                          _buildSettingsOption(
                            icon: Icons.account_tree,
                            iconColor: Colors.grey,
                            title: "Account Controls",
                            onTap: () => _navigateToAccountControls(),
                          ),

                          // Logout Option - Added with proper styling and confirmation
                          _buildSettingsOption(
                            icon: Icons.logout,
                            iconColor: Colors.red,
                            title: "Logout",
                            onTap: () => _showLogoutConfirmation(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              color: Colors.white,
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
                      const Icon(
                        Icons.directions_bus_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const Icon(
                        Icons.home_outlined,
                        color: Color(0xFF4A90E2),
                        size: 28,
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
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

  Widget _buildSettingsOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Jost',
            color: title == "Logout" ? Colors.red : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  void _showTopUpModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TopUpModal(
        currentBalance: walletBalance,
        onTopUp: _handleTopUp,
      ),
    );
  }

  void _showTransactionHistory() {
    context.push('/transaction_history');
  }

  void _handleTopUp(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final newBalance = walletBalance + amount;

      // Update wallet balance in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'walletBalance': newBalance});

      // Add transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'type': 'topup',
        'amount': amount,
        'description': 'Wallet Top Up',
        'timestamp': Timestamp.now(),
        'balanceAfter': newBalance,
      });

      setState(() {
        walletBalance = newBalance;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallet topped up with GHS ${amount.toStringAsFixed(2)}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Top up failed: $e')),
      );
    }
  }

  void _navigateToBasicInfo() {
    context.push('/basic_user_info');
  }

  void _navigateToTravelPreferences() {
    context.push('/travel_preferences');
  }

  void _toggleActiveStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final newStatus = !(userProfile['isActive'] ?? true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isActive': newStatus});

      setState(() {
        userProfile['isActive'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account ${newStatus ? 'activated' : 'deactivated'}'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update failed: $e')),
      );
    }
  }

  void _navigateToPaymentSettings() {
    context.push('/payment_settings');
  }

  void _navigateToTravelHistory() {
    context.push('/my_trips');
  }

  void _navigateToSupport() {
    context.push('/support_settings');
  }

  void _navigateToAccountControls() {
    context.push('/account_controls');
  }

  // NEW: Show logout confirmation dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout? You'll need to sign in again to access your account.",
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // NEW: Perform the actual logout
  void _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Navigate to sign-in screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        context.go('/sip_sign_in');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class TopUpModal extends StatefulWidget {
  final double currentBalance;
  final Function(double) onTopUp;

  const TopUpModal({
    Key? key,
    required this.currentBalance,
    required this.onTopUp,
  }) : super(key: key);

  @override
  _TopUpModalState createState() => _TopUpModalState();
}

class _TopUpModalState extends State<TopUpModal> {
  double selectedAmount = 20.0;
  final List<double> quickAmounts = [10.0, 20.0, 50.0, 100.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Title
          const Text(
            "Top Up Wallet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),

          const SizedBox(height: 24),

          // Quick Amount Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  "Select Amount (GHS)",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Jost',
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: quickAmounts.map((amount) {
                    final isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => setState(() => selectedAmount = amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF667eea) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          "GHS ${amount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black,
                            fontFamily: 'Jost',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Balance Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "New Balance:",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Jost',
                        ),
                      ),
                      Text(
                        "GHS ${(widget.currentBalance + selectedAmount).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                          fontFamily: 'Jost',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onTopUp(selectedAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Top Up GHS ${selectedAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
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
        ],
      ),
    );
  }
}