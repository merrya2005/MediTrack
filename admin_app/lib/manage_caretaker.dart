import 'package:flutter/material.dart';

class ManageCaretakers extends StatefulWidget {
  const ManageCaretakers({super.key});

  @override
  State<ManageCaretakers> createState() => _ManageCaretakersState();
}

class _ManageCaretakersState extends State<ManageCaretakers> {
  // State to toggle between List View and Add Form
  bool _isAddingNew = false;

  // --- MOCK DATA ---
  final List<Map<String, String>> _caretakers = List.generate(
    5,
    (index) => {
      'id': 'CT00${index + 1}',
      'name': 'Caretaker User ${index + 1}',
      'email': 'caretaker${index + 1}@gmail.com',
      'contact': '+91 987654321$index',
      'address': '123 Street, City $index',
      'status': 'Active',
    },
  );

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                Text(
                  _isAddingNew ? "Add New Caretaker" : "Caretaker List",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isAddingNew
                      ? "Fill in the details below to register a new caretaker."
                      : "Manage authorized caretakers and their access.",
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
              icon: Icon(_isAddingNew ? Icons.arrow_back : Icons.add),
              label: Text(_isAddingNew ? "Back to List" : "Add Caretaker"),
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

        // --- 2. CONTENT AREA ---
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: _isAddingNew ? _buildAddForm() : _buildTable(),
          ),
        ),
      ],
    );
  }

  // --- WIDGET: DATA TABLE ---
  Widget _buildTable() {
    if (_caretakers.isEmpty) {
      return const Center(child: Text("No caretakers found."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          dataRowHeight: 60,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Photo')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _caretakers.map((caretaker) {
            return DataRow(
              cells: [
                DataCell(Text(caretaker['id']!)),
                DataCell(
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                ),
                DataCell(
                  Text(
                    caretaker['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(Text(caretaker['email']!)),
                DataCell(Text(caretaker['contact']!)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _nameController.text = caretaker['name']!;
                            _emailController.text = caretaker['email']!;
                            _contactController.text = caretaker['contact']!;
                            _addressController.text = caretaker['address']!;
                            _isAddingNew = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _caretakers.remove(caretaker);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- WIDGET: ADD FORM ---
  Widget _buildAddForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 16,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _nameController,
                    "Full Name",
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTextField(
                    _emailController,
                    "Email Address",
                    Icons.email,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _contactController,
                    "Phone Number",
                    Icons.phone,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _addressController,
              "Residential Address",
              Icons.location_on,
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    setState(() => _isAddingNew = false);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _saveCaretaker,
                  icon: const Icon(Icons.check),
                  label: const Text("Save Caretaker"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
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
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _saveCaretaker() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _caretakers.add({
          'id': 'CT00${_caretakers.length + 1}',
          'name': _nameController.text,
          'email': _emailController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'status': 'Active',
        });
        _isAddingNew = false;
      });
      _clearForm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Caretaker Saved")));
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _contactController.clear();
    _addressController.clear();
    _passwordController.clear();
  }
}
