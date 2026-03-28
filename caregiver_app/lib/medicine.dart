import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:intl/intl.dart';

class AddPatientMedicineScreen extends StatefulWidget {
  final int caregiverId;
  const AddPatientMedicineScreen({super.key, required this.caregiverId});

  @override
  State<AddPatientMedicineScreen> createState() => _AddPatientMedicineScreenState();
}

class _AddPatientMedicineScreenState extends State<AddPatientMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController(text: "30");
  
  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _time;
  String? _selectedCategoryId;
  String? _selectedPatientId;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch Categories
      final catData = await supabase.from('tbl_medicinecategory').select();
      
      // Fetch Managed Patients
      final regData = await supabase
          .from('tbl_request')
          .select('*, tbl_patient(id, patient_name)')
          .eq('caregiver_id', widget.caregiverId)
          .eq('request_status', 1);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(catData);
        _patients = List<Map<String, dynamic>>.from(regData)
            .map((r) => r['tbl_patient'] as Map<String, dynamic>)
            .toList();
            
        // remove duplicates
        final map = <int, Map<String, dynamic>>{};
        for (var p in _patients) {
          map[p['id']] = p;
        }
        _patients = map.values.toList();
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked; else _toDate = picked;
      });
    }
  }

  Future<void> _submitMedicine() async {
    if (!_formKey.currentState!.validate() || _fromDate == null || _toDate == null || _time == null || _selectedCategoryId == null || _selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields including Time and Patient")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final medicineResponse = await supabase.from('tbl_medicine').insert({
        'medicine_name': _nameController.text.trim(),
        'medicine_description': _descController.text.trim(),
        'medicine_fromdate': _fromDate!.toIso8601String(),
        'medicine_todate': _toDate!.toIso8601String(),
        'medicine_time': '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        'medicine_status': 1,
        'medicinecategory_id': int.parse(_selectedCategoryId!),
        'patient_id': int.parse(_selectedPatientId!),
      }).select().single();

      await supabase.from('tbl_stock').insert({
        'stock_count': int.parse(_stockController.text),
        'medicine_id': medicineResponse['id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine successfully added for patient!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error adding medicine: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add medicine"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Patient Medicine"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                decoration: InputDecoration(
                  labelText: "Select Patient",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _patients.map((p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text(p['patient_name']),
                )).toList(),
                onChanged: (val) => setState(() => _selectedPatientId = val),
              ),
              const SizedBox(height: 16),
              
              _buildField(_nameController, "Medicine Name", Icons.medication_outlined),
              _buildField(_descController, "Dosage Instructions (e.g. 1-0-1)", Icons.info_outline),
              
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Category",
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['category_name']),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _dateTile("From", _fromDate, () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _dateTile("To", _toDate, () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 20),
              
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Daily Reminder Time", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(_time == null ? "Select Time" : _time!.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.access_time, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              _buildField(_stockController, "Initial Stock Count (e.g. 30)", Icons.inventory_2_outlined, keyboardType: TextInputType.number),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitMedicine,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE MEDICINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(date == null ? "Select Date" : DateFormat('dd MMM, yyyy').format(date), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
