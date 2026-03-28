import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _patientId;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profileData = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).single();
      _patientId = profileData['id'];

      final data = await supabase
          .from('tbl_complaint')
          .select()
          .eq('patient_id', _patientId!)
          .order('created_at', ascending: false);
      
      setState(() {
        _complaints = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    if (_patientId == null) return;

    setState(() => _isSending = true);
    try {
      await supabase.from('tbl_complaint').insert({
        'complaint_title': _titleController.text.trim(),
        'complaint_content': _contentController.text.trim(),
        'patient_id': _patientId,
        'complaint_reply_status': 0, // 0 = Pending
      });

      _titleController.clear();
      _contentController.clear();
      _fetchComplaints();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint submitted successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Error submitting complaint: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to submit complaint")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Complaints & Support"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Register a Complaint", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Subject",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Describe your issue",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _isSending ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("SUBMIT COMPLAINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text("Your Complaints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                    ? const Center(child: Text("No complaints found", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          final int status = complaint['complaint_reply_status'] ?? 0;
                          final bool isResolved = status == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(complaint['complaint_title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: isResolved ? Colors.green[50] : Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                                        child: Text(isResolved ? "Resolved" : "Pending", style: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(complaint['complaint_content'] ?? "", style: TextStyle(color: Colors.grey[700])),
                                  if (isResolved && complaint['complaint_reply'] != null) ...[
                                    const Divider(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Reply from Admin:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(complaint['complaint_reply'], style: const TextStyle(color: Colors.blueGrey)),
                                        ],
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
