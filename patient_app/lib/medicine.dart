import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';

class Medicine extends StatefulWidget {
  const Medicine({super.key});

  @override
  State<Medicine> createState() => _MedicineState();
}

class _MedicineState extends State<Medicine> {
  TextEditingController _medicineNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _fromDateController = TextEditingController();
  TextEditingController _toDateController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        _fromDateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
        _toDateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _registerMedicine() async {
    try {
      await supabase.from('tbl_medicine').insert({
        'medicine_name': _medicineNameController.text,
        'medicine_description': _descriptionController.text,
        'medicine_fromdate': _fromDate?.toIso8601String(),
        'medicine_todate': _toDate?.toIso8601String(),
        'medicine_status': '1',
        'medicine_date': DateTime.now().toIso8601String(),
        'medicinecategory_id': _categoryController.text,
        // 'patient_id': supabase.auth.currentUser?.id,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medicine registered successfully')),
      );
    } catch (e) {
      print("Error occurred while registering medicine: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error registering medicine')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: Icon(Icons.home), title: Text("Medicine Page")),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/medicine.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _medicineNameController,
                  decoration: InputDecoration(
                    hintText: 'Medicine Name',
                    prefixIcon: Icon(Icons.medication),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Medicine Details',
                    prefixIcon: Icon(Icons.check_circle),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _fromDateController,
                  readOnly: true,
                  onTap: () => _selectFromDate(context),
                  decoration: InputDecoration(
                    hintText: 'From Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _toDateController,
                  readOnly: true,
                  onTap: () => _selectToDate(context),
                  decoration: InputDecoration(
                    hintText: 'To Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    hintText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _registerMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: BeveledRectangleBorder(),
                  ),
                  child: Text("Submit", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
