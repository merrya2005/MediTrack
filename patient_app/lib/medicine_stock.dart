import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/medicine.dart';
import 'package:intl/intl.dart';

class MedicineStock extends StatefulWidget {
  const MedicineStock({super.key});

  @override
  State<MedicineStock> createState() => _MedicineStockState();
}

class _MedicineStockState extends State<MedicineStock> {
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicinesWithStock();
  }

  Future<void> _fetchMedicinesWithStock() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user.email!).single();
      final patientId = patientData['id'];

      final data = await supabase
          .from('tbl_medicine')
          .select('*, tbl_stock(stock_count, id), tbl_medicinecategory(medicinecategory_name)')
          .eq('patient_id', patientId);
      
      if (mounted) setState(() => _medicines = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching stock: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logIntake(Map<String, dynamic> medicine) async {
    final stock = medicine['tbl_stock'] as List;
    if (stock.isEmpty || stock[0]['stock_count'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Out of stock! Please refill.")));
      return;
    }

    try {
      final stockId = stock[0]['id'];
      final newCount = stock[0]['stock_count'] - 1;

      // Update Stock
      await supabase.from('tbl_stock').update({'stock_count': newCount}).eq('id', stockId);

      // Log Intake Entry
      final user = supabase.auth.currentUser;
      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user!.email!).single();
      
      await supabase.from('tbl_intake_log').insert({
        'medicine_id': medicine['id'],
        'patient_id': patientData['id'],
        'intake_datetime': DateTime.now().toIso8601String(),
      });

      // Refresh UI
      _fetchMedicinesWithStock();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Logged intake for ${medicine['medicine_name']}. Remaining: $newCount"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint("Error logging intake: $e");
    }
  }

  void _writeNfcTag(int medicineId) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NFC is not supported or disabled!"), backgroundColor: Colors.red));
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nfc_rounded, size: 64, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text("Write NFC Tag", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Hold a blank or existing NFC sticker near the back of your phone. We will format and securely link it to this medicine database ID.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            const LinearProgressIndicator(color: Colors.indigo),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                NfcManager.instance.stopSession();
                Navigator.pop(c);
              }, 
              child: const Text("CANCEL")
            ),
          ],
        ),
      ),
    );

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      final ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
         NfcManager.instance.stopSession(errorMessage: "Tag is not ndef writable.");
         if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tag is not NDEF writable!"), backgroundColor: Colors.red));
         }
         return;
      }

      final record = NdefRecord.createText(medicineId.toString());
      final message = NdefMessage([record]);

      try {
        await ndef.write(message);
        NfcManager.instance.stopSession();
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NFC Tag officially registered to this medicine!"), backgroundColor: Colors.green));
        }
      } catch (e) {
        NfcManager.instance.stopSession(errorMessage: e.toString());
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Write failed: $e"), backgroundColor: Colors.red));
        }
      }
    });
  }
  

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nfc, color: Colors.indigo),
            SizedBox(width: 8),
            Text("Smart NFC Guide"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("1. Getting Started", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Purchase blank NFC stickers (e.g., NTAG213) and attach them to the bottom of your medicine bottles."),
              SizedBox(height: 12),
              Text("2. Linking a Bottle", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Tap the 'LINK TAG' button next to your medicine below. Hold the sticker to the back of your phone (near the camera) to securely pair it!"),
              SizedBox(height: 12),
              Text("3. Daily Intake", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("When it is time for your medicine, your phone will flash a Live Notification. Tap 'TAP NFC TO VERIFY' on the popup and hold the bottle to your phone."),
              SizedBox(height: 12),
              Text("4. Auto Stock Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Successfully verifying the bottle automatically records your intake time and deducts 1 stock from your virtual inventory. If stock falls to 5, you'll be warned automatically!"),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("I UNDERSTAND")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const Medicine())),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Medication", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMedicinesWithStock,
        child: Column(
          children: [
            // Modern Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Inventory", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      Text("Manage your medication stock", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  IconButton(onPressed: _showGuideDialog, icon: const Icon(Icons.help_outline_rounded, color: Colors.indigo)),
                ],
              ),
            ),
    
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _medicines.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _medicines.length,
                          itemBuilder: (context, index) {
                            final med = _medicines[index];
                            final stock = med['tbl_stock'] as List;
                            final stockCount = stock.isNotEmpty ? stock[0]['stock_count'] : 0;
                            
                            return _buildMedicineCard(med, stockCount);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No medicines added yet", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med, int stockCount) {
    final bool isLow = stockCount < 5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['medicine_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(med['tbl_medicinecategory']?['medicinecategory_name'] ?? 'General', 
                      style: TextStyle(color: Colors.indigo[400], fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              _stockBadge(stockCount, isLow),
            ],
          ),
          const SizedBox(height: 12),
          Text(med['medicine_description'], style: TextStyle(color: Colors.grey[600])),
          const Divider(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Schedule", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  Text("${DateFormat('MMM d').format(DateTime.parse(med['medicine_fromdate']))} - ${DateFormat('MMM d').format(DateTime.parse(med['medicine_todate']))}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _writeNfcTag(med['id']),
                    icon: const Icon(Icons.nfc, size: 16, color: Colors.indigo),
                    label: const Text("LINK TAG", style: TextStyle(color: Colors.indigo, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.indigo.shade200),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _logIntake(med),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("TAKE NOW", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(int count, bool isLow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$count left",
        style: TextStyle(color: isLow ? Colors.red[700] : Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
