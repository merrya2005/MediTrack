import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final res = await supabase
          .from('tbl_complaint')
          .select('*, tbl_caregiver(caregiver_name, caregiver_email), tbl_patient(patient_name, patient_email)')
          .order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReplyDialog(Map<String, dynamic> complaint) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reply to Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Issue: ${complaint['complaint_title']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(complaint['complaint_content']),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Your Reply",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              
              try {
                await supabase.from('tbl_complaint').update({
                  'complaint_reply': replyController.text.trim(),
                  'complaint_reply_status': 1, // 1 = resolved
                }).eq('id', complaint['id']);
                
                if (mounted) {
                  Navigator.pop(context);
                  _fetchComplaints();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reply sent!"), backgroundColor: Colors.green));
                }
              } catch (e) {
                debugPrint("Error replying: $e");
              }
            },
            child: const Text("Send Reply"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return _complaints.isEmpty
        ? const Center(child: Text("No complaints logged.", style: TextStyle(color: Colors.grey, fontSize: 18)))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _complaints.length,
            itemBuilder: (context, index) {
              final c = _complaints[index];
              final bool isResolved = c['complaint_reply_status'] == 1;

              String senderName = "Unknown";
              String senderType = "";
              if (c['patient_id'] != null && c['tbl_patient'] != null) {
                senderName = c['tbl_patient']['patient_name'] ?? "Unknown";
                senderType = "Patient";
              } else if (c['caregiver_id'] != null && c['tbl_caregiver'] != null) {
                senderName = c['tbl_caregiver']['caregiver_name'] ?? "Unknown";
                senderType = "Caregiver";
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Text(senderType, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: isResolved ? Colors.green[50] : Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                            child: Text(isResolved ? "Resolved" : "Pending", style: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(c['complaint_title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(c['complaint_content'] ?? "", style: TextStyle(color: Colors.grey[800])),
                      if (isResolved && c['complaint_reply'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Admin Reply", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(c['complaint_reply']),
                            ],
                          ),
                        ),
                      ],
                      if (!isResolved) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _showReplyDialog(c),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white),
                            icon: const Icon(Icons.reply),
                            label: const Text("Reply"),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
  }
}
