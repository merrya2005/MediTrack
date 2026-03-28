import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class ManagePatient extends StatefulWidget {
  const ManagePatient({super.key});

  @override
  State<ManagePatient> createState() => _ManagePatientState();
}

class _ManagePatientState extends State<ManagePatient> {
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
      final response = await supabase
          .from("tbl_patient")
          .select('*, tbl_place(place_name)');

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching patients: $e");
    } finally {
      setState(() => _isLoading = false);
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
                      "Patient Directory",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Comprehensive list of all patients registered in the system.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _fetchPatients,
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh List",
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _patients.isEmpty
                      ? const Center(child: Text("No patients found."))
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowHeight: 60,
                                dataRowHeight: 60,
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                columns: const [
                                  DataColumn(label: Text('Patient')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Contact')),
                                  DataColumn(label: Text('Location')),
                                  DataColumn(label: Text('Gender')),
                                  DataColumn(label: Text('Date of Birth')),
                                  DataColumn(label: Text('Joined')),
                                ],
                                rows: _patients.map((patient) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.blue[50],
                                              backgroundImage: patient['patient_photo'] != null
                                                  ? NetworkImage(patient['patient_photo'])
                                                  : null,
                                              child: patient['patient_photo'] == null
                                                  ? const Icon(Icons.person,
                                                      size: 18, color: Colors.blue)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              patient['patient_name'] ?? "N/A",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(patient['patient_email'] ?? "N/A")),
                                      DataCell(Text(patient['patient_contact'] ?? "N/A")),
                                      DataCell(Text(patient['tbl_place']?['place_name'] ?? "N/A")),
                                      DataCell(Text(patient['patient_gender'] ?? "N/A")),
                                      DataCell(Text(patient['patient_dob'] ?? "N/A")),
                                      DataCell(
                                        Text(
                                          patient['created_at'] != null
                                              ? DateTime.parse(patient['created_at'])
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0]
                                              : "N/A",
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
