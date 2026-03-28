import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/chat.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _caregivers = [];
  bool _isLoading = true;
  int? _patientId;

  @override
  void initState() {
    super.initState();
    _fetchCaregivers();
  }

  Future<void> _fetchCaregivers() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).single();
      _patientId = patientData['id'];

      // Fetch accepted requests where this patient is involved
      final requests = await supabase
          .from('tbl_request')
          .select('*, tbl_caregiver(*)')
          .eq('patient_id', _patientId!)
          .eq('request_status', 1);
          
      setState(() {
        final List<Map<String, dynamic>> rawRequests = List<Map<String, dynamic>>.from(requests ?? []);
        _caregivers = [];
        
        for (var r in rawRequests) {
          if (r['tbl_caregiver'] != null) {
            _caregivers.add(r['tbl_caregiver'] as Map<String, dynamic>);
          }
        }
        
        // Remove duplicates if any
        final map = <int, Map<String, dynamic>>{};
        for (var c in _caregivers) {
          map[c['id']] = c;
        }
        _caregivers = map.values.toList();
      });
    } catch (e) {
      debugPrint("Error fetching chat caregivers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Chat list error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
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
                  Text("Messages", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  Text("Talk to your caregivers", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              IconButton(onPressed: _fetchCaregivers, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E))),
            ],
          ),
        ),

        Expanded(
          child: _caregivers.isEmpty
              ? const Center(child: Text("No connected caregivers yet.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _caregivers.length,
                  itemBuilder: (context, index) {
                    final caregiver = _caregivers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.2)),
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                              backgroundImage: caregiver['caregiver_photo'] != null && caregiver['caregiver_photo'].toString().isNotEmpty
                                  ? NetworkImage(caregiver['caregiver_photo'])
                                  : null,
                              radius: 25,
                              child: caregiver['caregiver_photo'] == null || caregiver['caregiver_photo'].toString().isEmpty
                                  ? const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E))
                                  : null,
                            ),
                          ),
                          title: Text(caregiver['caregiver_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                          subtitle: const Text("Tap to start chatting", style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF0F766E)),
                          onTap: () {
                            if (_patientId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    patientId: _patientId!,
                                    caregiverName: caregiver['caregiver_name'],
                                    caregiverId: caregiver['id'],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
