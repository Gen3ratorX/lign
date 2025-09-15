import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BasicUserInfoScreen extends StatefulWidget {
  final bool isFirstTime; // true if called during signup flow

  const BasicUserInfoScreen({Key? key, this.isFirstTime = false}) : super(key: key);

  @override
  _BasicUserInfoScreenState createState() => _BasicUserInfoScreenState();
}

class _BasicUserInfoScreenState extends State<BasicUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();

  String selectedGender = '';
  DateTime? dateOfBirth;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      _loadExistingData();
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emergencyContactController.text = data['emergencyContact'] ?? '';
          _addressController.text = data['address'] ?? '';
          selectedGender = data['gender'] ?? '';
          if (data['dateOfBirth'] != null) {
            dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isFirstTime
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isFirstTime ? "Complete Your Profile" : "Basic User Information",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Jost',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isFirstTime) ...[
                      const Text(
                        "We need some basic information to personalize your ride experience.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'Jost',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // First Name
                    _buildTextField(
                      controller: _firstNameController,
                      label: "First Name",
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Last Name
                    _buildTextField(
                      controller: _lastNameController,
                      label: "Last Name",
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your phone number';
                        }
                        if (value!.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Gender Selection
                    const Text(
                      "Gender",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Jost',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildGenderOption("Male"),
                        const SizedBox(width: 16),
                        _buildGenderOption("Female"),
                        const SizedBox(width: 16),
                        _buildGenderOption("Other"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Date of Birth
                    GestureDetector(
                      onTap: _selectDateOfBirth,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dateOfBirth != null
                                    ? "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}"
                                    : "Select Date of Birth",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: dateOfBirth != null ? Colors.black : Colors.grey[500],
                                  fontFamily: 'Jost',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Emergency Contact
                    _buildTextField(
                      controller: _emergencyContactController,
                      label: "Emergency Contact",
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter an emergency contact';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Address
                    _buildTextField(
                      controller: _addressController,
                      label: "Address",
                      maxLines: 3,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  widget.isFirstTime ? "Complete Profile" : "Save Changes",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Jost',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Jost',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Jost',
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            gender,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
              fontFamily: 'Jost',
            ),
          ),
        ),
      ),
    );
  }

  void _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => dateOfBirth = picked);
    }
  }

  void _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }
    if (dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'gender': selectedGender,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        'emergencyContact': _emergencyContactController.text.trim(),
        'address': _addressController.text.trim(),
        'email': user.email,
        'profileCompleted': true,
        'updatedAt': Timestamp.now(),
      };

      // If first time, also add initial wallet balance and other defaults
      if (widget.isFirstTime) {
        userData.addAll({
          'walletBalance': 50.0,
          'isActive': true,
          'joinedDate': Timestamp.now(),
          'totalTrips': 0,
          'preferences': {
            'notifications': true,
            'smsAlerts': true,
            'emailUpdates': false,
          }
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.isFirstTime) {
        // Navigate to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/commuter_home',
              (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }
}