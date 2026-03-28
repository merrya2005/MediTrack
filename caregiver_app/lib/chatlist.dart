import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:caregiver_app/chat.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  int? _caregiverId;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final caregiverData = await supabase.from('tbl_caregiver').select('id').eq('caregiver_email', user.email!).single();
      _caregiverId = caregiverData['id'];

      // Fetch accepted requests for this caregiver
      final requests = await supabase
          .from('tbl_request')
          .select('*, tbl_patient(*)')
          .eq('caregiver_id', _caregiverId!)
          .eq('request_status', 1);
          
      setState(() {
        _patients = List<Map<String, dynamic>>.from(requests).map((r) => r['tbl_patient'] as Map<String, dynamic>).toList();
        
        // Remove duplicates if multiple requests exist for the same patient
        final map = <int, Map<String, dynamic>>{};
        for (var p in _patients) {
          map[p['id']] = p;
        }
        _patients = map.values.toList();
      });
    } catch (e) {
      debugPrint("Error fetching chat patients: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: _patients.isEmpty
          ? const Center(child: Text("No connected patients yet.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      radius: 25,
                      child: const Icon(Icons.person, color: Colors.indigo),
                    ),
                    title: Text(patient['patient_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to start chatting", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                    onTap: () {
                      if (_caregiverId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              patientId: patient['id'],
                              patientName: patient['patient_name'],
                              caregiverId: _caregiverId!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
