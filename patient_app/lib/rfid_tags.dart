import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';

class RFIDTagsScreen extends StatefulWidget {
  const RFIDTagsScreen({super.key});

  @override
  State<RFIDTagsScreen> createState() => _RFIDTagsScreenState();
}

class _RFIDTagsScreenState extends State<RFIDTagsScreen> {
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeds();
  }

  Future<void> _fetchMeds() async {
    try {
      final user = supabase.auth.currentUser;
      final patient = await supabase.from('tbl_patient').select('id').eq('patient_email', user!.email!).single();
      final data = await supabase.from('tbl_medicine').select().eq('patient_id', patient['id']);
      setState(() => _medicines = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching meds for tags: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _associateTag(int medId, String medName) {
    final uidController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Link Tag to $medName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nfc_rounded, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text("Enter the unique ID of your RFID sticker/tag:"),
            TextField(
              controller: uidController,
              decoration: const InputDecoration(hintText: "e.g. A1-B2-C3-D4", labelText: "Tag UID"),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tag ${uidController.text} linked to $medName!")));
              Navigator.pop(context);
            },
            child: const Text("SAVE TAG"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RFID Tag Manager"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select a medicine to link with a physical RFID tag:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final med = _medicines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.indigoAccent, child: Icon(Icons.style_rounded, color: Colors.white)),
                          title: Text(med['medicine_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text("Click to link an RFID tag"),
                          onTap: () => _associateTag(med['id'], med['medicine_name']),
                          trailing: const Icon(Icons.link, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
