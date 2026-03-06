import 'package:flutter/material.dart';

class ManagePatients extends StatefulWidget {
  const ManagePatients({super.key});

  @override
  State<ManagePatients> createState() => _ManagePatientsState();
}

class _ManagePatientsState extends State<ManagePatients> {
  // Toggle between Grid View and Add Form
  bool _isAddingNew = false;

  // --- MOCK DATA ---
  final List<Map<String, String>> _patients = List.generate(
    6,
    (index) => {
      'id': 'P00${index + 1}',
      'name': 'Patient Name ${index + 1}',
      'age': '${60 + index}',
      'stage': '${(index % 3) + 1}',
      'condition': 'Alzheimer\'s',
    },
  );

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAddingNew ? "Register New Patient" : "Patient Records",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isAddingNew
                      ? "Enter the patient details to create a new profile."
                      : "Overview of all patients under supervision.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNew = !_isAddingNew;
                  if (!_isAddingNew) _clearForm();
                });
              },
              icon: Icon(_isAddingNew ? Icons.arrow_back : Icons.person_add),
              label: Text(_isAddingNew ? "Back to Grid" : "Add Patient"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAddingNew ? Colors.grey[800] : Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- CONTENT AREA ---
        Expanded(child: _isAddingNew ? _buildAddForm() : _buildGrid()),
      ],
    );
  }

  // --- WIDGET: PATIENT GRID ---
  Widget _buildGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  patient['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Age: ${patient['age']} | Stage ${patient['stage']}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET: ADD FORM ---
  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(_nameController, "Patient Name", Icons.badge),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _ageController,
                    "Age",
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTextField(
                    _conditionController,
                    "Primary Condition",
                    Icons.health_and_safety,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isAddingNew = false),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save Patient Record"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _savePatient() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _patients.add({
          'id': 'P00${_patients.length + 1}',
          'name': _nameController.text,
          'age': _ageController.text,
          'condition': _conditionController.text,
        });
        _isAddingNew = false;
      });
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _conditionController.clear();
  }
}
