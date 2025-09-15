import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> userTickets = [];
  bool isLoading = true;
  double walletBalance = 50.00; // This should come from users collection
  late TabController _purchaseTabController;

  @override
  void initState() {
    super.initState();
    _purchaseTabController = TabController(length: 2, vsync: this);
    _loadUserData();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Load wallet balance from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        walletBalance = (userData?['walletBalance'] ?? 50.0).toDouble();
      }

      // Load user tickets
      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: user.uid)
          .orderBy('purchaseTime', descending: true)
          .get();

      setState(() {
        userTickets = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _purchaseTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                    "Tickets",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (userTickets.isNotEmpty) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              "A",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Jost',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: _showPurchaseModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "buy Ticket",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Jost',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userTickets.isEmpty
                  ? _buildEmptyState()
                  : _buildTicketsList(),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Icon(
                        Icons.home_outlined,
                        color: Color(0xFF4A90E2),
                        size: 28,
                      ),
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 26,
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

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Icon(
                Icons.close,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No active ticket found. Please",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Jost',
              ),
            ),
            Text(
              "purchase one to continue your",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Jost',
              ),
            ),
            Text(
              "journey",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Jost',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Time header
          if (userTickets.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "Arrives: 10:30 AM",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Expires: 11:15 AM",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Jost',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tickets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: userTickets.length,
              itemBuilder: (context, index) {
                final ticket = userTickets[index];
                return _buildTicketCard(ticket, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    final isInactive = ticket['status'] == 'inactive';
    final isActive = ticket['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInactive ? Colors.grey[50] : const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF4A90E2),
            width: 3,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['destination'] ?? "Central Station",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isInactive ? Colors.grey[500] : const Color(0xFF4A90E2),
                    fontFamily: 'Jost',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Arrives: ${ticket['arrivalTime'] ?? '10:30 AM 4/4'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isInactive ? Colors.grey[400] : const Color(0xFF4A90E2),
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Valid Until: ${ticket['validUntil'] ?? '5/4/25'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isInactive ? Colors.grey[400] : const Color(0xFF4A90E2),
                        fontFamily: 'Jost',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isActive ? "A" : "IN",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Jost',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PurchaseTicketModal(
        walletBalance: walletBalance,
        onPurchase: _handleTicketPurchase,
      ),
    );
  }

  void _handleTicketPurchase(int quantity, double totalPrice) async {
    if (totalPrice > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(quantity, totalPrice);
    if (!confirmed) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update wallet balance in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'walletBalance': walletBalance - totalPrice});

      // Update local wallet balance
      setState(() {
        walletBalance -= totalPrice;
      });

      // Create tickets
      for (int i = 0; i < quantity; i++) {
        await FirebaseFirestore.instance.collection('tickets').add({
          'userId': user.uid,
          'destination': 'Central Station',
          'arrivalTime': '10:30 AM 4/4',
          'validUntil': '5/4/25',
          'status': 'active',
          'price': 4.00,
          'purchaseTime': Timestamp.now(),
          'ticketId': 'TKT-${DateTime.now().millisecondsSinceEpoch}',
        });
      }

      // Reload tickets
      _loadUserData();

      Navigator.pop(context); // Close modal

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased $quantity ticket${quantity > 1 ? 's' : ''}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }

  Future<bool> _showConfirmationDialog(int quantity, double totalPrice) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Confirmation",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Jost',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Buy $quantity active ticket${quantity > 1 ? 's' : ''} for Bus-201. Price ${totalPrice.toStringAsFixed(2)} cedis.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Jost',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Jost',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
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
      ),
    ) ?? false;
  }
}

class PurchaseTicketModal extends StatefulWidget {
  final double walletBalance;
  final Function(int, double) onPurchase;

  const PurchaseTicketModal({
    Key? key,
    required this.walletBalance,
    required this.onPurchase,
  }) : super(key: key);

  @override
  _PurchaseTicketModalState createState() => _PurchaseTicketModalState();
}

class _PurchaseTicketModalState extends State<PurchaseTicketModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int ticketQuantity = 2;
  final double ticketPrice = 4.00;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = ticketQuantity * ticketPrice;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'Jost',
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Inactive"),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Route Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildDetailRow("Route", "Circle to Legon", Icons.my_location, const Color(0xFF4A90E2)),
                  const SizedBox(height: 20),
                  _buildDetailRow("Departs", "7:45 AM • June 27", Icons.schedule, Colors.orange),
                  const SizedBox(height: 20),
                  _buildDetailRow("Route ID", "BUS-201", Icons.directions_bus, const Color(0xFF4A90E2)),
                  const SizedBox(height: 20),

                  // Ticket quantity selector
                  Row(
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          "Tickets",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'Jost',
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "0",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontFamily: 'Jost',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  ticketQuantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Jost',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildDetailRow("Ticket ID", "TKT-00983", Icons.confirmation_number, Colors.purple),
                  const SizedBox(height: 20),
                  _buildDetailRow("Price", "GHS ${totalPrice.toStringAsFixed(2)}", Icons.attach_money, Colors.green),

                  const SizedBox(height: 32),

                  // Wallet balance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          "Wallet Balance: GHS ${widget.walletBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            fontFamily: 'Jost',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Purchase button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalPrice <= widget.walletBalance
                          ? () => widget.onPurchase(ticketQuantity, totalPrice)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        totalPrice <= widget.walletBalance
                            ? "Buy Ticket"
                            : "Insufficient Balance",
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
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontFamily: 'Jost',
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Jost',
            ),
          ),
        ),
      ],
    );
  }
}