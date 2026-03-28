import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:patient_app/main.dart';
import 'package:intl/intl.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).single();
      final patientId = patientData['id'];

      final data = await supabase
          .from('tbl_request')
          .select('*, tbl_caregiver(*)')
          .eq('patient_id', patientId)
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

  Future<void> _cancelRequest(int requestId) async {
    try {
      await supabase.from('tbl_request').delete().eq('id', requestId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request cancelled successfully")));
      _fetchRequests();
    } catch (e) {
      debugPrint("Cancel error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text("Request History", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[100], height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      return _buildRequestCard(req);
                    },
                  ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final cg = req['tbl_caregiver'];
    final status = req['request_status']; // 0: Pending, 1: Accepted, 2: Rejected
    
    Color statusColor = Colors.orange;
    String statusText = "Pending";
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (status == 1) {
      statusColor = Colors.green;
      statusText = "Accepted";
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 2) {
      statusColor = Colors.red;
      statusText = "Rejected";
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: statusColor.withOpacity(0.1),
                      image: cg['caregiver_photo'] != null ? DecorationImage(image: NetworkImage(cg['caregiver_photo']), fit: BoxFit.cover) : null,
                    ),
                    child: cg['caregiver_photo'] == null ? Icon(Icons.person, color: statusColor, size: 30) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cg['caregiver_name'] ?? 'Caregiver', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF111827))),
                        const SizedBox(height: 4),
                        Text(req['request_details'] ?? 'Request for assistance', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 6),
                        Text(statusText, style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (status == 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _cancelRequest(req['id']),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: Text("CANCEL REQUEST", style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 1) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.green[50]?.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 18, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Caregiver has accepted! You can now chat with them.", style: GoogleFonts.outfit(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
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
          Icon(Icons.assignment_ind_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No caregiver requests yet", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Requested history will appear here", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
