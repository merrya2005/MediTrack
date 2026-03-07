import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class ManagePatient extends StatefulWidget {
  const ManagePatient({super.key});

  @override
  State<ManagePatient> createState() => _ManagePatientState();
}

class _ManagePatientState extends State<ManagePatient> {
  // Store fetched data
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() => _isLoading = true);

      // Fetching from Supabase
      final List<dynamic> response = await supabase
          .from("tbl_patient")
          .select();

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching patients: $e");
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
              onPressed: _fetchPatients,
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
    if (_patients.isEmpty) {
      return const Center(child: Text("No patients found."));
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
              rows: _patients.map((patient) {
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
                            patient['patient_name']?.toString() ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(patient['patient_email']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_contact']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_address']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_password']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_certificate']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_idproof']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_gender']?.toString() ?? "N/A"),
                    ),
                    DataCell(
                      Text(patient['patient_experience']?.toString() ?? "N/A"),
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
