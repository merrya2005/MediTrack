import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patient_app/login.dart';
import 'package:patient_app/main.dart';

class PatientReg extends StatefulWidget {
  const PatientReg({super.key});

  @override
  State<PatientReg> createState() => _PatientRegState();
}

class _PatientRegState extends State<PatientReg> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  int? _selectedDistrict;
  int? _selectedPlace;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _places = [];

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  Future<void> _fetchDistricts() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() => _districts = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching districts: $e");
    }
  }

  Future<void> _fetchPlaces(int districtId) async {
    try {
      final response = await supabase
          .from('tbl_place')
          .select()
          .eq('district_id', districtId);
      setState(() {
        _places = List<Map<String, dynamic>>.from(response);
        _selectedPlace = null;
      });
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedPlace == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Sign up with Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        String? photoUrl;
        
        if (_selectedImage != null) {
          try {
            final fileExt = _selectedImage!.path.split('.').last;
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            final filePath = 'patient_photos/$fileName';
            
            await supabase.storage.from('patient_photos').upload(filePath, _selectedImage!);
            photoUrl = supabase.storage.from('patient_photos').getPublicUrl(filePath);
          } catch (e) {
            debugPrint("Image upload error: $e");
          }
        }

        // 2. Insert into tbl_patient
        await supabase.from('tbl_patient').insert({
          'patient_name': _nameController.text.trim(),
          'patient_email': _emailController.text.trim(),
          'patient_password': _passwordController.text.trim(),
          'patient_contact': _phoneController.text.trim(),
          'patient_dob': _selectedDate!.toIso8601String().split('T')[0],
          'patient_gender': _selectedGender,
          'patient_address': _addressController.text.trim(),
          'place_id': _selectedPlace,
          if (photoUrl != null) 'patient_photo': photoUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully! Please login."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientLoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Create Account"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                          child: _selectedImage == null
                              ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: Text("Profile Photo (Optional)", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    const SizedBox(height: 24),
                    const Text(
                      "Personal Information",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, "Full Name", Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, "Email Address", Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, "Password", Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        )),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Contact Number", Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    
                    // Gender & DOB Column
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        prefixIcon: Icon(Icons.wc_rounded),
                      ),
                      items: ["Male", "Female", "Other"]
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Date of Birth",
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        child: Text(_selectedDate == null
                            ? "Select Date"
                            : _selectedDate!.toIso8601String().split('T')[0]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                      "Address & Location",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_addressController, "Residential Address", Icons.home_outlined),
                    const SizedBox(height: 16),
                    
                    // District & Place Column
                    DropdownButtonFormField<int>(
                      value: _selectedDistrict,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "District",
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: _districts
                          .map((d) => DropdownMenuItem(
                              value: d['id'] as int,
                              child: Text(d['district_name'])))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrict = val;
                          _selectedPlace = null;
                        });
                        _fetchPlaces(val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedPlace,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Place",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _places
                          .map((p) => DropdownMenuItem(
                              value: p['id'] as int,
                              child: Text(p['place_name'])))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPlace = val),
                      disabledHint: const Text("Select District First"),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("CREATE ACCOUNT"),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
    );
  }
}
