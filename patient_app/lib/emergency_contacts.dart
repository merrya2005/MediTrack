import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // First get parent patient_id
        final patient = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).maybeSingle();
        if (patient != null) {
          final data = await supabase
              .from('tbl_emergency_contact')
              .select()
              .eq('patient_id', patient['id']);
          setState(() => _contacts = List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Emergency Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: relationController, decoration: const InputDecoration(labelText: "Relation (e.g. Son, Doc)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = supabase.auth.currentUser;
                final patient = await supabase.from('tbl_patient').select('id').eq('patient_email', user!.email!).single();
                
                await supabase.from('tbl_emergency_contact').insert({
                  'contact_name': nameController.text,
                  'contact_phone': phoneController.text,
                  'contact_relation': relationController.text,
                  'patient_id': patient['id'],
                });
                Navigator.pop(context);
                _fetchContacts();
              } catch (e) {
                debugPrint("Error adding contact: $e");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty 
            ? const Center(child: Text("No emergency contacts found.\nAdd one for safety.", textAlign: TextAlign.center))
            : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.red[50],
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 40),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "In case of emergency, these contacts can be notified automatically.",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[100],
                      child: const Icon(Icons.phone, color: Colors.red),
                    ),
                    title: Text(contact['contact_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${contact['contact_relation'] ?? ''} | ${contact['contact_phone'] ?? ''}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: Colors.red[700],
        icon: const Icon(Icons.add_call, color: Colors.white),
        label: const Text("ADD CONTACT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
