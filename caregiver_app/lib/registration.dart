import 'dart:io';
import 'package:caregiver_app/login.dart';
import 'package:caregiver_app/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverReg extends StatefulWidget {
  const CaregiverReg({super.key});

  @override
  State<CaregiverReg> createState() => _CaregiverRegState();
}

class _CaregiverRegState extends State<CaregiverReg> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedPlace;
  String? _selectedGender;
  DateTime? _selectedDob;
  
  File? _photoFile;
  File? _idProofFile;
  
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  Future<void> _fetchDistricts() async {
    try {
      final data = await supabase.from('tbl_district').select();
      setState(() => _districts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching districts: $e");
    }
  }

  Future<void> _fetchPlaces(String districtId) async {
    try {
      final data = await supabase.from('tbl_place').select().eq('district_id', districtId);
      setState(() {
        _places = List<Map<String, dynamic>>.from(data);
        _selectedPlace = null;
      });
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo (Camera)'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _photoFile = File(pickedFile.path);
          } else {
            _idProofFile = File(pickedFile.path);
          }
        });
      }
    }
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  bool _isEligibleAge() {
    if (_selectedDob == null) return false;
    final today = DateTime.now();
    int age = today.year - _selectedDob!.year;
    if (today.month < _selectedDob!.month || 
        (today.month == _selectedDob!.month && today.day < _selectedDob!.day)) {
      age--;
    }
    return age >= 18;
  }

  Future<String?> _uploadFile(File file, String pathFolder) async {
    try {
      final fileName = "${pathFolder}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await supabase.storage.from('uploads').upload(fileName, file);
      return supabase.storage.from('uploads').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> _registerCaregiver() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDob == null) {
      _showError("Please select your Date of Birth.");
      return;
    }
    if (!_isEligibleAge()) {
      _showError("You must be at least 18 years old to register as a partner.");
      return;
    }
    if (_selectedPlace == null) {
      _showError("Please select a place.");
      return;
    }
    if (_photoFile == null) {
      _showError("Please upload a profile photo.");
      return;
    }
    if (_idProofFile == null) {
      _showError("Please upload an ID Proof document.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        // Upload images
        String? photoUrl = await _uploadFile(_photoFile!, "caregiver_photos");
        String? idProofUrl = await _uploadFile(_idProofFile!, "caregiver_idproofs");

        await supabase.from('tbl_caregiver').insert({
          'caregiver_name': _nameController.text.trim(),
          'caregiver_email': _emailController.text.trim(),
          'caregiver_password': _passwordController.text.trim(),
          'caregiver_dob': _selectedDob!.toIso8601String().split('T')[0],
          'caregiver_contact': _phoneController.text.trim(),
          'caregiver_photo': photoUrl ?? '',
          'caregiver_address': _addressController.text.trim(),
          'caregiver_status': 0, // Pending
          'caregiver_certificate': _qualificationController.text.trim(),
          'caregiver_idproof': idProofUrl ?? '',
          'caregiver_gender': _selectedGender,
          'caregiver_experience': _experienceController.text.trim(),
          'place_id': _selectedPlace,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Application submitted! Waiting for admin approval."), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CaregiverLoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      _showError("Registration failed. Email might already be in use.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Registration"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Upload at the top
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                        child: _photoFile == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1),
                          radius: 20,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle("Personal Information"),
              const SizedBox(height: 16),
              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              _buildTextField(_emailController, "Business Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, "Contact Number", Icons.phone_outlined, keyboardType: TextInputType.phone),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Required";
                    if (val.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
              ),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.wc_rounded)),
                items: ["Male", "Female", "Other"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                validator: (val) => val == null ? "Required" : null,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectDob(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDob == null ? "Tap to select DOB" : _selectedDob!.toIso8601String().split('T')[0],
                    style: TextStyle(color: _selectedDob == null ? Colors.grey[600] : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle("Professional Details"),
              const SizedBox(height: 16),
              _buildTextField(_qualificationController, "Highest Qualification", Icons.school_outlined),
              _buildTextField(_experienceController, "Years of Experience", Icons.work_outline, keyboardType: TextInputType.number),
              
              const SizedBox(height: 16),
              Text("ID Proof Upload", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _idProofFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_idProofFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text("Tap to upload ID Proof", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle("Location & Address"),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(labelText: "District", prefixIcon: Icon(Icons.map_outlined)),
                items: _districts.map((d) => DropdownMenuItem(
                  value: d['id'].toString(),
                  child: Text(d['district_name']),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedDistrict = val);
                  if (val != null) _fetchPlaces(val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPlace,
                decoration: const InputDecoration(labelText: "Place", prefixIcon: Icon(Icons.location_on_outlined)),
                items: _places.map((p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text(p['place_name']),
                )).toList(),
                onChanged: (val) => setState(() => _selectedPlace = val),
              ),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Full Residential Address", Icons.home_outlined, maxLines: 3),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerCaregiver,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT APPLICATION"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: true,
        ),
        validator: (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    );
  }
}
