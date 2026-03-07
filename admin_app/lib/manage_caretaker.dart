import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class ManageCaretakers extends StatefulWidget {
  const ManageCaretakers({super.key});

  @override
  State<ManageCaretakers> createState() => _ManageCaretakersState();
}

class _ManageCaretakersState extends State<ManageCaretakers> {
  // Store fetched data
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

      // Fetching from Supabase
      final List<dynamic> response = await supabase
          .from("tbl_caregiver")
          .select();

      setState(() {
        _caretakers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching caretakers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Caretaker List",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "View authorized caretakers and their registered details.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            // Refresh Button
            IconButton(
              onPressed: _fetchCaretakers,
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Data",
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- 2. CONTENT AREA ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTable(),
        ),
      ],
    );
  }

  // --- WIDGET: DATA TABLE ---
  Widget _buildTable() {
    if (_caretakers.isEmpty) {
      return const Center(child: Text("No caretakers found."));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              dataRowHeight: 60,
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Contact')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('password')),
                DataColumn(label: Text('certificate')),
                DataColumn(label: Text('idproof')),
                DataColumn(label: Text('gender')),
                DataColumn(label: Text('experience')),
              ],
              rows: _caretakers.map((caretaker) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.teal,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            caretaker['caregiver_name']?.toString() ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(caretaker['caregiver_email']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(caretaker['caregiver_contact']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(caretaker['caregiver_address']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(
                        caretaker['caregiver_password']?.toString() ?? "N/A",
                      ),
                    ),
                    DataCell(
                      Text(
                        caretaker['caregiver_certificate']?.toString() ?? "N/A",
                      ),
                    ),
                    DataCell(
                      Text(caretaker['caregiver_idproof']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(caretaker['caregiver_gender']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(
                        caretaker['caregiver_experience']?.toString() ?? "N/A",
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
