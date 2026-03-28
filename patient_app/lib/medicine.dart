import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';
import 'package:intl/intl.dart';

class Medicine extends StatefulWidget {
  const Medicine({super.key});

  @override
  State<Medicine> createState() => _MedicineState();
}

class _MedicineState extends State<Medicine> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController(text: "30");
  
  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _time;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await supabase.from('tbl_medicinecategory').select();
      setState(() => _categories = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
      });
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
    if (!_formKey.currentState!.validate() || _fromDate == null || _toDate == null || _time == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields including Time")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch patient ID
      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).single();
      final patientId = patientData['id'];

      // 2. Insert Medicine
      final medicineResponse = await supabase.from('tbl_medicine').insert({
        'medicine_name': _nameController.text.trim(),
        'medicine_description': _descController.text.trim(),
        'medicine_fromdate': _fromDate!.toIso8601String(),
        'medicine_todate': _toDate!.toIso8601String(),
        'medicine_time': '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}', 
        'medicine_status': 1,
        'medicinecategory_id': int.parse(_selectedCategoryId!),
        'patient_id': patientId,
      }).select().single();

      // 3. Insert Initial Stock
      await supabase.from('tbl_stock').insert({
        'stock_count': int.parse(_stockController.text),
        'medicine_id': medicineResponse['id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine successfully added!")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error adding medicine: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add medicine")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Medicine"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(_nameController, "Medicine Name", Icons.medication_outlined),
              _buildField(_descController, "Dosage Instructions (e.g. 1-0-1)", Icons.info_outline),
              
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: "Category", prefixIcon: Icon(Icons.category_outlined)),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['medicinecategory_name'] ?? 'General'),
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
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Daily Time", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
              
              _buildField(_stockController, "Initial Stock Count (Tablets/Bottles)", Icons.inventory_2_outlined, keyboardType: TextInputType.number),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitMedicine,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE MEDICINE"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(date == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(date), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
