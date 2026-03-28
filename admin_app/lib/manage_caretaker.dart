import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class ManageCaretakers extends StatefulWidget {
  const ManageCaretakers({super.key});

  @override
  State<ManageCaretakers> createState() => _ManageCaretakersState();
}

class _ManageCaretakersState extends State<ManageCaretakers> {
  List<Map<String, dynamic>> _caretakers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaretakers();
  }

  Future<void> _fetchCaretakers() async {
    try {
      setState(() => _isLoading = true);
      final response = await supabase
          .from("tbl_caregiver")
          .select('*, tbl_place(place_name)');

      setState(() {
        _caretakers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching caretakers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, int status) async {
    try {
      await supabase
          .from("tbl_caregiver")
          .update({'caregiver_status': status})
          .eq('id', id);
      
      _fetchCaretakers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 1 ? "Caretaker Approved" : "Caretaker Rejected"),
            backgroundColor: status == 1 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Caretaker Management",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Verify and manage registered caregivers on the platform.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _fetchCaretakers,
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh List",
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _caretakers.isEmpty
                      ? const Center(child: Text("No caregivers registered yet."))
                      : ListView.builder(
                          itemCount: _caretakers.length,
                          itemBuilder: (context, index) {
                            final caretaker = _caretakers[index];
                            final int status = caretaker['caregiver_status'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFFE3F2FD),
                                      backgroundImage: caretaker['caregiver_photo'] != null
                                          ? NetworkImage(caretaker['caregiver_photo'])
                                          : null,
                                      child: caretaker['caregiver_photo'] == null
                                          ? const Icon(Icons.person,
                                              size: 30, color: Color(0xFF1A73E8))
                                          : null,
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            caretaker['caregiver_name'] ?? "Unnamed",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            caretaker['caregiver_email'] ?? "",
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 12,
                                            children: [
                                              _buildInfoTag(
                                                  Icons.phone_android,
                                                  caretaker['caregiver_contact'] ??
                                                      "No contact"),
                                              _buildInfoTag(
                                                  Icons.location_on_outlined,
                                                  caretaker['tbl_place']?['place_name'] ??
                                                      "Unknown"),
                                              _buildInfoTag(
                                                  Icons.person_pin_outlined,
                                                  caretaker['caregiver_gender'] ??
                                                      "N/A"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      children: [
                                        _buildStatusBadge(status),
                                        const SizedBox(height: 12),
                                        if (status == 0)
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _updateStatus(
                                                    caretaker['id'], 1),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 8),
                                                ),
                                                child: const Text("Approve"),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () => _updateStatus(
                                                    caretaker['id'], 2),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(
                                                      color: Colors.red),
                                                ),
                                                child: const Text("Reject"),
                                              ),
                                            ],
                                          )
                                        else if (status == 1)
                                          TextButton.icon(
                                            onPressed: () => _updateStatus(
                                                caretaker['id'], 2),
                                            icon: const Icon(Icons.block,
                                                size: 16, color: Colors.grey),
                                            label: const Text("Disable",
                                                style: TextStyle(color: Colors.grey)),
                                          )
                                        else
                                          TextButton.icon(
                                            onPressed: () => _updateStatus(
                                                caretaker['id'], 1),
                                            icon: const Icon(Icons.restore,
                                                size: 16, color: Colors.blue),
                                            label: const Text("Re-Enable",
                                                style: TextStyle(color: Colors.blue)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int status) {
    String text = "Pending";
    Color color = Colors.orange;
    if (status == 1) {
      text = "Approved";
      color = Colors.green;
    } else if (status == 2) {
      text = "Rejected";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
