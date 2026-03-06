import 'package:flutter/material.dart';
import 'package:patient_app/login.dart';
import 'package:patient_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientReg extends StatefulWidget {
  const PatientReg({super.key});

  @override
  State<PatientReg> createState() => _PatientRegState();
}

class _PatientRegState extends State<PatientReg> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _emergencyController = TextEditingController();

  Future<void> _registerPatient() async {
    AuthResponse response = await supabase.auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );
    try {
      await supabase.from('tbl_patient').insert({
        'id': response.user?.id,
        'patient_name': _nameController.text,
        'patient_email': _emailController.text,
        'patient_password': _passwordController.text,
        'patient_contact': _phoneController.text,
        'patient_dob': _ageController.text,
        'patient_gender': _genderController.text,
        'patient_address': _addressController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Patient registered successfully!")),
      );
    } catch (e) {
      print("Error occurred while registering patient: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(),
        child: Center(
          // Centers the form on larger screens
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? screenWidth * 0.1 : 20,
              vertical: 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 1. LOGO & BRAND SECTION ---
                _buildBrandSection(),
                const SizedBox(height: 40),

                // --- 2. MAIN FORM CONTAINER ---
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                  ), // Prevents form from being too wide
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWideScreen ? 50 : 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Create Patient Account",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),

                          _buildResponsiveRow(isWideScreen, [
                            _buildField(
                              "Full Name",
                              Icons.person_outline,
                              _nameController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter full name'
                                  : null,
                            ),
                            _buildField(
                              "Email Address",
                              Icons.email_outlined,
                              _emailController,
                              validator: (value) {
                                if (value!.isEmpty) return 'Please enter email';
                                if (!RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                ).hasMatch(value))
                                  return 'Please enter a valid email';
                                return null;
                              },
                            ),
                          ]),
                          _buildResponsiveRow(isWideScreen, [
                            _buildField(
                              "Password",
                              Icons.lock_outline,
                              _passwordController,
                              isObscure: true,
                              validator: (value) => value!.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            _buildField(
                              "Phone Number",
                              Icons.phone_android_outlined,
                              _phoneController,
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter phone number'
                                  : null,
                            ),
                          ]),
                          _buildResponsiveRow(isWideScreen, [
                            _buildField(
                              "Age",
                              Icons.calendar_today_outlined,
                              _ageController,
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter age' : null,
                            ),
                            _buildField(
                              "Gender",
                              Icons.wc_outlined,
                              _genderController,
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter gender' : null,
                            ),
                          ]),
                          _buildField(
                            "Residential Address",
                            Icons.map_outlined,
                            _addressController,
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter address' : null,
                          ),
                          _buildField(
                            "Emergency Contact",
                            Icons.contact_emergency_outlined,
                            _emergencyController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter emergency contact'
                                : null,
                          ),

                          const SizedBox(height: 40),

                          // --- 3. ACTION BUTTONS ---
                          _buildActions(isWideScreen),

                          const SizedBox(height: 30),
                          const Divider(),
                          const SizedBox(height: 20),

                          // --- 4. ALREADY HAVE AN ACCOUNT ---
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have a patient record? "),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PatientLoginScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Login here",
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer Copyright
                const SizedBox(height: 40),
                Text(
                  "© 2026 MediTrack Health Systems. All rights reserved.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      children: [
        // Logo Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: Colors.teal,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        // App Name
        const Text(
          "MediTrack",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.black87,
          ),
        ),
        Text(
          "Healthcare Management Simplified",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(bool isWide, List<Widget> children) {
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: child,
                  ),
                ),
              )
              .toList(),
        ),
      );
    } else {
      return Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: child,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.teal, size: 20),
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            hintText: "Enter $label",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isWide) {
    return SizedBox(
      width: double.infinity,
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _cancelButton(),
                const SizedBox(width: 16),
                _submitButton(),
              ],
            )
          : Column(
              children: [
                _submitButton(),
                const SizedBox(height: 12),
                _cancelButton(),
              ],
            ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _registerPatient();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(220, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        "SUBMIT REGISTRATION",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cancelButton() {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(150, 55),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("CANCEL", style: TextStyle(color: Colors.black54)),
    );
  }
}
