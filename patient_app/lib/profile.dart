import 'package:flutter/material.dart';
import 'package:patient_app/login.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/emergency_contacts.dart';
import 'package:patient_app/rfid_tags.dart';
import 'package:patient_app/complaints.dart';
import 'package:patient_app/my_requests.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
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
            .from('tbl_patient')
            .select('*, tbl_place(place_name)')
            .eq('patient_email', user.email!)
            .maybeSingle();
        if (mounted) setState(() => _profileData = data);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileData == null) return const Scaffold(body: Center(child: Text("Profile not found")));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: const Color(0xFF0F766E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        Text("Manage your account settings", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.1), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF0F766E).withOpacity(0.05),
                        child: const Icon(Icons.person_outline_rounded, size: 50, color: Color(0xFF0F766E)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profileData!['patient_name'] ?? "User",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      _profileData!['patient_email'] ?? "",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    
                    _profileCard([
                      _profileTile("Personal Details", Icons.badge_outlined, () {
                        // Future: Navigate to details
                      }),
                      _profileTile("My Caregiver Requests", Icons.person_search_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen()));
                      }),
                      _profileTile("Edit Profile", Icons.edit_note_rounded, () {
                        // Future: Navigate to edit
                      }),
                      _profileTile("Change Password", Icons.shield_outlined, () {
                        // Future: Navigate to change password
                      }),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _profileCard([
                      _profileTile("Emergency Contacts", Icons.contact_emergency_outlined, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()));
                      }),
                      _profileTile("NFC Tag Management", Icons.nfc_rounded, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RFIDTagsScreen()));
                      }),
                      _profileTile("Report Complaints", Icons.help_outline_rounded, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintsPage()));
                      }),
                    ]),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PatientLoginScreen()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 12),
                          Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey[50]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _profileTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
