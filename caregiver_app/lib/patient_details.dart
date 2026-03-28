import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:caregiver_app/chat.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final int caregiverId;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  List<Map<String, dynamic>> _meds = [];
  List<Map<String, dynamic>> _vitals = [];
  List<Map<String, dynamic>> _logs = [];
  Map<int, int> _stockMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final meds = await supabase.from('tbl_medicine').select().eq('patient_id', widget.patientId);
      final vitals = await supabase.from('tbl_vitals').select().eq('patient_id', widget.patientId);
      final stock = await supabase.from('tbl_stock').select().filter('medicine_id', 'in', meds.map((m) => m['id']).toList());
      
      // Fetch last 20 intake logs
      final logs = await supabase
          .from('tbl_intake_log')
          .select('*, tbl_medicine(medicine_name, medicine_time)')
          .eq('patient_id', widget.patientId)
          .order('intake_datetime', ascending: false)
          .limit(20);
      
      final Map<int, int> sMap = {};
      for (var s in stock) { sMap[s['medicine_id']] = s['stock_count']; }

      if (mounted) {
        setState(() {
          _meds = List<Map<String, dynamic>>.from(meds);
          _vitals = List<Map<String, dynamic>>.from(vitals);
          _logs = List<Map<String, dynamic>>.from(logs);
          _stockMap = sMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(patientId: widget.patientId, patientName: widget.patientName, caregiverId: widget.caregiverId))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDetails,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Current Inventory & Stock", Icons.inventory_2_rounded, Colors.orange),
                  const SizedBox(height: 16),
                  _meds.isEmpty ? _emptyState("No medicines registered") : Column(children: _meds.map((m) => _stockTile(m)).toList()),

                  const SizedBox(height: 32),
                  _sectionHeader("Recent Intake History", Icons.history_rounded, Colors.green),
                  const SizedBox(height: 16),
                  _logs.isEmpty ? _emptyState("No intake logs yet") : Column(children: _logs.map((l) => _logTile(l)).toList()),

                  const SizedBox(height: 32),
                  _sectionHeader("Health Vitals", Icons.favorite_rounded, Colors.redAccent),
                  const SizedBox(height: 16),
                  _vitals.isEmpty ? _emptyState("No vitals recorded") : _vitalsGrid(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))]);
  }

  Widget _stockTile(Map<String, dynamic> med) {
    final stock = _stockMap[med['id']] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(med['medicine_name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text("Schedule: ${med['medicine_time']}", style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$stock Left", style: TextStyle(fontWeight: FontWeight.bold, color: stock <= 5 ? Colors.red : Colors.green)),
              Text("In Stock", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logTile(Map<String, dynamic> log) {
    final DateTime intakeTime = DateTime.parse(log['intake_datetime']);
    final String timeStr = DateFormat('MMM d, hh:mm a').format(intakeTime);
    final String schedTime = log['tbl_medicine']?['medicine_time'] ?? "--:--";
    
    // Check if taken on time (simple logic: same hour)
    final intakeHour = intakeTime.hour;
    final intakeMin = intakeTime.minute;
    final schedParts = schedTime.split(':');
    bool onTime = false;
    if (schedParts.length == 2) {
      final sHour = int.parse(schedParts[0]);
      final sMin = int.parse(schedParts[1]);
      final diff = (intakeHour * 60 + intakeMin) - (sHour * 60 + sMin);
      if (diff.abs() < 30) onTime = true; // Within 30 mins is on time
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[50]!)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: onTime ? Colors.green : Colors.orange, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(log['tbl_medicine']?['medicine_name'] ?? "Medicine", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 11))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: (onTime ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(onTime ? "ON TIME" : "DELAYED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: onTime ? Colors.green[800] : Colors.orange[800])),
          ),
        ],
      ),
    );
  }

  Widget _vitalsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: _vitals.length,
      itemBuilder: (context, index) {
        final v = _vitals[index];
        return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(v['vital_type'], style: TextStyle(color: Colors.grey[500], fontSize: 11)), const SizedBox(height: 4), Text(v['vital_value'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));
      },
    );
  }

  Widget _emptyState(String text) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)), child: Center(child: Text(text, style: TextStyle(color: Colors.grey[400]))));
  }
}
