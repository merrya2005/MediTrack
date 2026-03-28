import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:caregiver_app/login.dart';
import 'package:caregiver_app/complaints.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverProfileTab extends StatefulWidget {
  const CaregiverProfileTab({super.key});

  @override
  State<CaregiverProfileTab> createState() => _CaregiverProfileTabState();
}

class _CaregiverProfileTabState extends State<CaregiverProfileTab> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tbl_caregiver')
            .select()
            .eq('caregiver_email', user.email!)
            .maybeSingle();
        setState(() => _profileData = data);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_profileData == null) return const Center(child: Text("Profile not found"));

    return Column(
      children: [
        const SizedBox(height: 30),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.indigo,
          backgroundImage: _profileData!['caregiver_photo'] != null && _profileData!['caregiver_photo'].toString().isNotEmpty
              ? NetworkImage(_profileData!['caregiver_photo'])
              : null,
          child: _profileData!['caregiver_photo'] == null || _profileData!['caregiver_photo'].toString().isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          _profileData!['caregiver_name'] ?? "Unknown",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          _profileData!['caregiver_email'] ?? "",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        _menuItem(
          context,
          Icons.account_circle_outlined,
          "My Profile",
          MyProfilePage(profileData: _profileData!),
        ),
        _menuItem(
          context,
          Icons.edit_outlined,
          "Edit Profile",
          EditProfilePage(profileData: _profileData!, onUpdate: _fetchProfile),
        ),
        _menuItem(
          context,
          Icons.lock_outline,
          "Change Password",
          const ChangePasswordPage(),
        ),
        _menuItem(
          context,
          Icons.report_problem_outlined,
          "Complaints",
          const ComplaintsPage(),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CaregiverLoginScreen()),
              );
            }
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            "Logout",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
    );
  }
}

class MyProfilePage extends StatelessWidget {
  final Map<String, dynamic> profileData;
  const MyProfilePage({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _dataRow("Name", profileData['caregiver_name'] ?? "N/A"),
            _dataRow("Email", profileData['caregiver_email'] ?? "N/A"),
            _dataRow("Phone", profileData['caregiver_contact'] ?? "N/A"),
            _dataRow("Experience", "${profileData['caregiver_experience'] ?? '0'} Years"),
            _dataRow("Address", profileData['caregiver_address'] ?? "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onUpdate;
  const EditProfilePage({super.key, required this.profileData, required this.onUpdate});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profileData['caregiver_name'] ?? "";
    _phoneController.text = widget.profileData['caregiver_contact'] ?? "";
    _expController.text = widget.profileData['caregiver_experience']?.toString() ?? "";
    _addressController.text = widget.profileData['caregiver_address'] ?? "";
    _emailController.text = widget.profileData['caregiver_email'] ?? ""; // Disabled
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('tbl_caregiver').update({
        'caregiver_name': _nameController.text.trim(),
        'caregiver_contact': _phoneController.text.trim(),
        'caregiver_experience': _expController.text.trim(),
        'caregiver_address': _addressController.text.trim(),
      }).eq('id', widget.profileData['id']);
      
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfuly!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Details"),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: "Email (Cannot be changed)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _expController,
              decoration: InputDecoration(
                labelText: "Years of Experience",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_newController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
      return;
    }
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: _newController.text));
      
      // Also update in our tbl_caregiver for consistency
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('tbl_caregiver').update({
          'caregiver_password': _newController.text
        }).eq('caregiver_email', user.email!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Password update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating password"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security"),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm New Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("UPDATE PASSWORD", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
