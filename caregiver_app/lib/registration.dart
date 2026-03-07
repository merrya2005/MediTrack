import 'package:caregiver_app/login.dart';
import 'package:caregiver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverReg extends StatefulWidget {
  const CaregiverReg({super.key});

  @override
  State<CaregiverReg> createState() => _CaregiverRegState();
}

class _CaregiverRegState extends State<CaregiverReg> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _emergencyController = TextEditingController();
  TextEditingController _qualificationController = TextEditingController();
  TextEditingController _experienceController = TextEditingController();
  TextEditingController _idProofController = TextEditingController();
  TextEditingController _placeIdController = TextEditingController();
  TextEditingController _photoController = TextEditingController();

  Future<void> _registerPatient() async {
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await supabase.from('tbl_caregiver').insert({
        'id': response.user?.id,
        'caregiver_name': _nameController.text,
        'caregiver_email': _emailController.text,
        'caregiver_contact': _phoneController.text,
        'caregiver_photo': _photoController.text,
        'caregiver_address': _addressController.text,
        'caregiver_password': _passwordController.text,
        'caregiver_status': _ageController.text,
        'caregiver_certificate': _qualificationController.text,
        'caregiver_idproof': _idProofController.text,
        'caregiver_gender': _genderController.text,
        'caregiver_experience': _experienceController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caregiver registered successfully!")),
      );
    } catch (e) {
      // ignore: avoid_print
      print("Error occurred while registering caregiver: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? true) {
      _registerPatient();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? screenWidth * 0.15 : 20,
            vertical: 40,
          ),
          child: Column(
            children: [
              // --- 1. BRANDING ---
              _buildBrandHeader(),
              const SizedBox(height: 30),

              // --- 2. REGISTRATION FORM ---
              Container(
                constraints: const BoxConstraints(maxWidth: 900),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isWideScreen ? 45 : 25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Professional Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Basic Info
                        _buildResponsiveRow(isWideScreen, [
                          _buildField(
                            "Full Name",
                            Icons.badge_outlined,
                            controller: _nameController,
                          ),
                          _buildField(
                            "Email Address",
                            Icons.email_outlined,
                            controller: _emailController,
                          ),
                        ]),
                        _buildResponsiveRow(isWideScreen, [
                          _buildField(
                            "Password",
                            Icons.lock_outline,
                            isObscure: true,
                            controller: _passwordController,
                          ),
                          _buildField(
                            "Phone Number",
                            Icons.phone_outlined,
                            controller: _phoneController,
                          ),
                        ]),
                        _buildResponsiveRow(isWideScreen, [
                          _buildField(
                            "Age",
                            Icons.calendar_month_outlined,
                            controller: _ageController,
                          ),
                          _buildField(
                            "Gender",
                            Icons.wc_outlined,
                            controller: _genderController,
                          ),
                        ]),

                        const Divider(height: 40),
                        const Text(
                          "Work & Qualifications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Professional Info
                        _buildResponsiveRow(isWideScreen, [
                          _buildField(
                            "Qualification",
                            Icons.school_outlined,
                            controller: _qualificationController,
                          ),
                          _buildField(
                            "Years of Experience",
                            Icons.history_outlined,
                            controller: _experienceController,
                          ),
                        ]),
                        _buildField(
                          "Residential Address",
                          Icons.home_work_outlined,
                          controller: _addressController,
                        ),
                        _buildField(
                          "ID Proof (URL/Reference)",
                          Icons.fact_check_outlined,
                          controller: _idProofController,
                        ),

                        const SizedBox(height: 40),

                        // --- 3. ACTIONS ---
                        _buildActions(isWideScreen),

                        const SizedBox(height: 25),
                        _buildAlreadyHaveAccount(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        const Icon(Icons.auto_graph_rounded, color: Colors.teal, size: 50),
        const SizedBox(height: 10),
        const Text(
          "Caregiver Portal",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          "Join our network of healthcare professionals",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    IconData icon, {
    bool isObscure = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
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
      ),
    );
  }

  Widget _buildResponsiveRow(bool isWide, List<Widget> children) {
    if (isWide) {
      return Row(
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
      );
    } else {
      return Column(children: children);
    }
  }

  Widget _buildActions(bool isWide) {
    return SizedBox(
      width: double.infinity,
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _btn(
                  "CANCEL",
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 15),
                _btn(
                  "SUBMIT APPLICATION",
                  isPrimary: true,
                  onPressed: _handleSubmit,
                ),
              ],
            )
          : Column(
              children: [
                _btn(
                  "SUBMIT APPLICATION",
                  isPrimary: true,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 10),
                _btn(
                  "CANCEL",
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
    );
  }

  Widget _btn(
    String label, {
    required bool isPrimary,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.teal : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.black54,
        minimumSize: const Size(200, 55),
        elevation: 0,
        side: isPrimary
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAlreadyHaveAccount() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already a partner? "),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CaregiverLoginScreen(),
                ),
              );
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
