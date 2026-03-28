import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:caregiver_app/patient_details.dart';
import 'package:caregiver_app/chat.dart';

class MyPatientsList extends StatefulWidget {
  const MyPatientsList({super.key});

  @override
  State<MyPatientsList> createState() => _MyPatientsListState();
}

class _MyPatientsListState extends State<MyPatientsList> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  int? _caregiverId;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final caregiverData = await supabase.from('tbl_caregiver').select('id').eq('caregiver_email', user.email!).single();
      _caregiverId = caregiverData['id'];

      if (_caregiverId == null) return;
      final data = await supabase
          .from('tbl_request')
          .select('*, tbl_patient(*)')
          .eq('caregiver_id', _caregiverId!)
          .order('id', ascending: false);
      
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int requestId, int status) async {
    try {
      await supabase.from('tbl_request').update({'request_status': status}).eq('id', requestId);
      _fetchRequests(); 
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("My Patients", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchRequests),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchRequests,
            child: _requests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final patient = req['tbl_patient'];
                      final int status = req['request_status'];

                      return _buildPatientCard(req, patient, status);
                    },
                  ),
          ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> req, Map<String, dynamic> patient, int status) {
    return GestureDetector(
      onTap: status == 1 ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => PatientDetailsScreen(patientId: patient['id'], patientName: patient['patient_name'], caregiverId: _caregiverId!))) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, backgroundColor: const Color(0xFF6366F1).withOpacity(0.1), child: Text(patient['patient_name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient['patient_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(patient['patient_contact'] ?? "No contact", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            if (status == 1) ...[
               const SizedBox(height: 16),
               const Divider(height: 1),
               const SizedBox(height: 12),
               Row(
                 children: [
                   const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.green),
                   const SizedBox(width: 8),
                   Text("ACTIVE CONNECTION", style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   TextButton.icon(
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(patientId: patient['id'], patientName: patient['patient_name'], caregiverId: _caregiverId!))),
                     icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                     label: const Text("MESSAGE", style: TextStyle(fontSize: 12)),
                   )
                 ],
               )
            ] else if (status == 0) ...[
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _updateStatus(req['id'], 2), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("REJECT"))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus(req['id'], 1), style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text("ACCEPT"))),
              ]),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("Registry Empty", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          Text("Incoming patient requests will appear here", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusBadge(int status) {
    String label = "Pending";
    Color color = Colors.orange;
    if (status == 1) { label = "Active"; color = Colors.green; }
    if (status == 2) { label = "Rejected"; color = Colors.red; }

    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
