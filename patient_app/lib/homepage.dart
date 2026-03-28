import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:intl/intl.dart';
import 'package:patient_app/caregiverlist.dart';
import 'package:patient_app/medicine.dart';
import 'package:patient_app/medicine_stock.dart';
import 'package:patient_app/my_requests.dart';
import 'package:patient_app/profile.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/chatlist.dart';
import 'package:patient_app/notifications.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _meds = [];
  List<Map<String, dynamic>> _vitals = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  
  Timer? _notificationTimer;
  StreamSubscription? _chatSubscription;
  final Set<int> _notifiedMeds = {};
  final Set<int> _notifiedLowStock = {};
  final Set<int> _notifiedMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _startGlobalNotifications();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _listenForChatUpdates(int patientId) {
    _chatSubscription?.cancel();
    _chatSubscription = supabase
        .from('tbl_chat')
        .stream(primaryKey: ['id'])
        .eq('chat_topatient', patientId)
        .listen((data) {
      if (!mounted) return;
      
      final unreadMessages = data.where((m) => m['chat_isseen'] == 0).toList();
      if (mounted) {
        setState(() => _unreadCount = unreadMessages.length);
        for (var msg in unreadMessages) {
          if (!_notifiedMessages.contains(msg['id'])) {
            _notifiedMessages.add(msg['id']);
            _triggerAlert("New message from your caregiver!", Icons.chat_bubble_rounded, color: Colors.blue[800]!);
          }
        }
      }
    }, onError: (e) => debugPrint("Chat sync error: $e"));
  }

  void _startGlobalNotifications() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (!mounted || _patientData == null) return;
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final reminderTimeStr = DateFormat('HH:mm').format(now.add(const Duration(minutes: 1)));

      for (var med in _meds) {
        if (med['medicine_time'] == reminderTimeStr && !_notifiedMeds.contains(med['id'])) {
          try {
            final logs = await supabase.from('tbl_intake_log').select().eq('medicine_id', med['id']).gte('intake_datetime', todayStr);
            if (logs.isEmpty) { _notifiedMeds.add(med['id']); _triggerAlert("Time for ${med['medicine_name']}!", Icons.alarm, color: const Color(0xFF0F766E)); }
          } catch (e) { debugPrint("Med noti error: $e"); }
        }
      }

      try {
        if (_meds.isNotEmpty) {
          final allStock = await supabase.from('tbl_stock').select('*, tbl_medicine(*)').filter('medicine_id', 'in', _meds.map((m) => m['id']).toList());
          for (var s in allStock) {
            if (s['stock_count'] <= 5 && !_notifiedLowStock.contains(s['id'])) {
              _notifiedLowStock.add(s['id']);
              _triggerAlert("Low Stock: ${s['tbl_medicine']['medicine_name']}!", Icons.inventory_2_rounded, color: Colors.orange[800]!);
            }
          }
        }
      } catch (e) { debugPrint("Stock noti error: $e"); }
    });
  }

  void _triggerAlert(String message, IconData icon, {Color color = Colors.teal}) async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)))]), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('tbl_patient').select().eq('patient_email', user.email!).maybeSingle();
        if (mounted) {
          setState(() => _patientData = data);
          if (data != null) {
            _listenForChatUpdates(data['id']);
            final meds = await supabase.from('tbl_medicine').select().eq('patient_id', data['id']);
            final vitals = await supabase.from('tbl_vitals').select().eq('patient_id', data['id']);
            if (mounted) {
              setState(() {
                _meds = List<Map<String, dynamic>>.from(meds);
                _vitals = List<Map<String, dynamic>>.from(vitals);
                _isLoading = false;
              });
            }
          } else {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> pages = [
      PatientDashboard(
        name: _patientData?['patient_name'] ?? "User",
        meds: _meds,
        vitals: _vitals,
        patientId: _patientData?['id'] ?? 0,
        onRefresh: _fetchDashboardData,
        onTabChange: (index) => setState(() => _currentIndex = index),
      ),
      const MedicineStock(),
      const ChatListScreen(),
      const CaregiversListView(),
      const PatientProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          const BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: "Stock"),
          BottomNavigationBarItem(icon: Badge(label: Text(_unreadCount.toString()), isLabelVisible: _unreadCount > 0, child: const Icon(Icons.chat_bubble_rounded)), label: "Messages"),
          const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Caregivers"),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
      body: pages[_currentIndex],
    );
  }
}

class PatientDashboard extends StatefulWidget {
  final String name;
  final int patientId;
  final List<Map<String, dynamic>> meds;
  final List<Map<String, dynamic>> vitals;
  final Function(int) onTabChange;
  final VoidCallback onRefresh;
  const PatientDashboard({super.key, required this.name, required this.meds, required this.vitals, required this.onTabChange, required this.onRefresh, required this.patientId});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  Future<void> _showRFIDSync({int? expectedMedId}) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NFC missing"), backgroundColor: Colors.orange)); return; }
    showModalBottomSheet(context: context, isDismissible: false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), builder: (c) => Container(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.nfc_rounded, size: 64, color: Color(0xFF0F766E)), const SizedBox(height: 16), const Text("Ready to Scan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 32), const LinearProgressIndicator(color: Color(0xFF0F766E)), const SizedBox(height: 16), TextButton(onPressed: () { NfcManager.instance.stopSession(); Navigator.pop(c); }, child: const Text("CANCEL"))])));
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      NfcManager.instance.stopSession();
      try {
        final ndef = Ndef.from(tag);
        if (ndef == null || ndef.cachedMessage == null) throw Exception("Empty tag");
        final payload = String.fromCharCodes(ndef.cachedMessage!.records.first.payload).substring(3);
        final int medicineId = int.parse(payload);
        if (expectedMedId != null && medicineId != expectedMedId) throw Exception("Wrong bottle");
        await supabase.from('tbl_intake_log').insert({'medicine_id': medicineId, 'patient_id': widget.patientId, 'intake_datetime': DateTime.now().toIso8601String()});
        final stock = await supabase.from('tbl_stock').select().eq('medicine_id', medicineId).maybeSingle();
        if (stock != null) { await supabase.from('tbl_stock').update({'stock_count': stock['stock_count'] - 1}).eq('id', stock['id']); if (mounted) { Navigator.pop(context); widget.onRefresh(); } }
      } catch (e) { if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); } }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("MediTrack", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: const Color(0xFFF9FAFB),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.1), shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F766E)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => NotificationsScreen(patientId: widget.patientId)))),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        color: const Color(0xFF0F766E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 32),
              _sectionHeader("Daily Schedule", () => widget.onTabChange(1), actionLabel: "See All"),
              const SizedBox(height: 12),
              widget.meds.isEmpty ? _emptyMedsCard() : Column(children: widget.meds.map((m) => _medicationTile(m)).toList()),
              const SizedBox(height: 32),
              const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 16),
              _quickActionsGrid(),
              const SizedBox(height: 32),
              _sectionHeader("Health Vitals", _showAddVitalsDialog, actionLabel: "+ Update"),
              const SizedBox(height: 12),
              _vitalsGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good Morning,", style: TextStyle(color: Colors.teal[50], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 30)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text("You have 3 medications due today. Stay healthy!", style: TextStyle(color: Colors.teal[50], fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAction, {String actionLabel = "+ Add"}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), TextButton(onPressed: onAction, child: Text(actionLabel, style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)))]);
  }

  void _showAddVitalsDialog() {
    final typeController = TextEditingController();
    final valueController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Vitals"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: typeController, decoration: const InputDecoration(labelText: "Type")), TextField(controller: valueController, decoration: const InputDecoration(labelText: "Value"))]), actions: [ElevatedButton(onPressed: () async {
      await supabase.from('tbl_vitals').insert({'vital_type': typeController.text, 'vital_value': valueController.text, 'patient_id': widget.patientId});
      Navigator.pop(context); widget.onRefresh();
    }, child: const Text("Save"))]));
  }

  Widget _emptyMedsCard() { return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)), child: Column(children: [Icon(Icons.medication_outlined, size: 48, color: Colors.grey[300]), const SizedBox(height: 12), Text("No meds scheduled", style: TextStyle(color: Colors.grey[500]))])); }

  Widget _medicationTile(Map<String, dynamic> med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[50]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(med['medicine_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937))), Text(med['medicine_description'] ?? "No instructions", style: TextStyle(fontSize: 12, color: Colors.grey[500]))])),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(med['medicine_time'] ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 16)),
              const Text("Take Now", style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _quickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5,
      children: [
        _actionCard("Messages", Icons.chat_bubble_rounded, Colors.teal, () => widget.onTabChange(2)),
        _actionCard("Add Medication", Icons.add_circle_outline_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const Medicine()))),
        _actionCard("Caregivers", Icons.people_rounded, Colors.blue, () => widget.onTabChange(3)),
        _actionCard("Stock Check", Icons.inventory_2_rounded, Colors.amber, () => widget.onTabChange(1)),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _vitalsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 1.8, 
        crossAxisSpacing: 16, 
        mainAxisSpacing: 16
      ),
      itemCount: widget.vitals.length,
      itemBuilder: (context, index) {
        final v = widget.vitals[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey[50]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                v['vital_type'], 
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  v['vital_value'], 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
