// screens/driver_profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'driver_service.dart';

class DriverProfileSetupScreen extends StatefulWidget {
  const DriverProfileSetupScreen({Key? key}) : super(key: key);

  @override
  _DriverProfileSetupScreenState createState() => _DriverProfileSetupScreenState();
}

class _DriverProfileSetupScreenState extends State<DriverProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _capacityController = TextEditingController();

  final DriverService _driverService = DriverService();
  bool isLoading = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _busNumberController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _checkExistingProfile() async {
    setState(() => isLoading = true);

    try {
      final driver = await _driverService.getCurrentDriver();
      if (driver != null) {
        setState(() {
          isEditing = true;
          _nameController.text = driver.name;
          _busNumberController.text = driver.busNumber;
          _licenseController.text = driver.licenseNumber;
          _phoneController.text = driver.phoneNumber;
          _capacityController.text = driver.capacity.toString();
        });
      }
    } catch (e) {
      print('Error checking existing profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Driver Profile' : 'Setup Driver Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isEditing
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        automaticallyImplyLeading: isEditing,
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...', style: TextStyle(fontFamily: 'Jost')),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        size: 40,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Update Your Profile' : 'Complete Your Driver Profile',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Jost',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? 'Make changes to your driver information'
                          : 'Please provide your driver information to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Jost',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form Fields
              _buildFormSection('Personal Information', [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildFormSection('Vehicle Information', [
                _buildTextField(
                  controller: _busNumberController,
                  label: 'Bus Number',
                  icon: Icons.directions_bus,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your bus number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _capacityController,
                  label: 'Bus Capacity (Number of Seats)',
                  icon: Icons.event_seat,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bus capacity';
                    }
                    final capacity = int.tryParse(value.trim());
                    if (capacity == null || capacity < 1) {
                      return 'Please enter a valid capacity';
                    }
                    if (capacity > 100) {
                      return 'Capacity seems too high';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildFormSection('License Information', [
                _buildTextField(
                  controller: _licenseController,
                  label: 'Driver License Number',
                  icon: Icons.credit_card,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your license number';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 32),

              // Save Button
              Container(
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
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEditing ? 'Update Profile' : 'Complete Setup',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jost',
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
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
          borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontFamily: 'Jost',
        ),
      ),
      style: const TextStyle(fontFamily: 'Jost'),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isEditing) {
        await _driverService.updateDriverProfile(
          name: _nameController.text.trim(),
          busNumber: _busNumberController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
        );
      } else {
        await _driverService.createDriverProfile(
          name: _nameController.text.trim(),
          busNumber: _busNumberController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          capacity: int.parse(_capacityController.text.trim()),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Profile updated successfully!' : 'Profile created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to driver home
        context.go('/driver_home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}