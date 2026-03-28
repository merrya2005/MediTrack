import 'dart:async';
import 'package:caregiver_app/main.dart';
import 'package:caregiver_app/mypatientlist.dart';
import 'package:caregiver_app/chatlist.dart';
import 'package:caregiver_app/profiile.dart';
import 'package:caregiver_app/medicine.dart';
import 'package:caregiver_app/patient_details.dart';
import 'package:caregiver_app/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _caregiverData;
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  int _activePatientsCount = 0;
  bool _isLoading = true;
  int _unreadCount = 0;
  Timer? _timer;
  StreamSubscription? _chatSubscription;

  final Set<int> _notifiedMeds = {};
  final Set<int> _notifiedIntakes = {};
  final Set<int> _notifiedMessages = {};
  List<Map<String, dynamic>> _patientMeds = [];

  final Color _themeColor = const Color(0xFF0F766E); // Unified Teal Theme

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _startLiveNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _listenForChatUpdates(int caregiverId) {
    _chatSubscription?.cancel();
    _chatSubscription = supabase
        .from('tbl_chat')
        .stream(primaryKey: ['id'])
        .eq('chat_tocaregiver', caregiverId)
        .listen((data) {
      if (!mounted) return;
      
      final unread = data.where((m) => m['chat_isseen'] == 0).toList();
      
      if (mounted) {
        setState(() => _unreadCount = unread.length);
        for (var msg in unread) {
          if (!_notifiedMessages.contains(msg['id'])) {
             _notifiedMessages.add(msg['id']);
             _sendAlert("New message from patient!", Icons.message_rounded, color: Colors.blue);
          }
        }
      }
    }, onError: (e) {
       debugPrint("Caregiver chat sync error: $e");
    });
  }

  void _startLiveNotifications() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (!mounted || _caregiverData == null) return;
      
      final now = DateTime.now();
      final reminderTimeStr = DateFormat('HH:mm').format(now.add(const Duration(minutes: 1)));

      for (var med in _patientMeds) {
        if (med['medicine_time'] == reminderTimeStr && !_notifiedMeds.contains(med['id'] + 100000)) {
          _notifiedMeds.add(med['id'] + 100000);
          _sendAlert("Reminder: ${med['tbl_patient']?['patient_name']} due for ${med['medicine_name']}!", Icons.notification_important, color: _themeColor);
        }
      }

      try {
        final patientIds = _activeRequests.map((r) => r['patient_id']).toList();
        if (patientIds.isNotEmpty) {
           final logs = await supabase.from('tbl_intake_log').select('*, tbl_patient(patient_name), tbl_medicine(medicine_name)').filter('patient_id', 'in', patientIds).order('intake_datetime', ascending: false).limit(10);
           for (var log in logs) {
             if (!_notifiedIntakes.contains(log['id'])) {
                _notifiedIntakes.add(log['id']);
                _sendAlert("${log['tbl_patient']['patient_name']} confirmed taking ${log['tbl_medicine']['medicine_name']}!", Icons.check_circle, color: Colors.green);
             }
           }
        }
      } catch (e) { debugPrint("Intake check err: $e"); }
    });
  }

  void _sendAlert(String message, IconData icon, {Color color = Colors.indigo}) async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.heavyImpact();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)))]),
           backgroundColor: color,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
         )
       );
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('tbl_caregiver').select().eq('caregiver_email', user.email!).maybeSingle();
        if (mounted) {
          setState(() => _caregiverData = data);
          if (data != null) {
            _listenForChatUpdates(data['id']);
            final active = await supabase.from('tbl_request').select('*, tbl_patient(*)').eq('caregiver_id', data['id']).eq('request_status', 1);
            final pending = await supabase.from('tbl_request').select('*, tbl_patient(*)').eq('caregiver_id', data['id']).eq('request_status', 0);
            final patientIds = List<int>.from(active.map((r) => r['patient_id']));
            List<dynamic> meds = [];
            if (patientIds.isNotEmpty) meds = await supabase.from('tbl_medicine').select('*, tbl_patient(patient_name)').filter('patient_id', 'in', patientIds);
            
            setState(() {
              _activeRequests = List<Map<String, dynamic>>.from(active);
              _pendingRequests = List<Map<String, dynamic>>.from(pending);
              _activePatientsCount = _activeRequests.length;
              _patientMeds = List<Map<String, dynamic>>.from(meds);
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Caregiver fetch profile error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequest(int id, int status) async {
    try {
      await supabase.from('tbl_request').update({'request_status': status}).eq('id', id);
      _fetchProfile();
    } catch (e) { debugPrint("Update status error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> pages = [
      CaregiverDashboard(
        caregiverId: _caregiverData?['id'] ?? 0,
        name: _caregiverData?['caregiver_name'] ?? "Partner",
        activeCount: _activePatientsCount,
        upcomingVisits: _activeRequests,
        pendingRequests: _pendingRequests,
        onAction: _updateRequest,
        onRefresh: _fetchProfile,
        themeColor: _themeColor,
      ),
      const MyPatientsList(),
      const ChatListScreen(),
      const CaregiverProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("MediTrack", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: _themeColor.withOpacity(0.08), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: _themeColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => NotificationsScreen(caregiverId: _caregiverData?['id'] ?? 0))),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: _themeColor,
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: "Patients"),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(_unreadCount.toString()),
              isLabelVisible: _unreadCount > 0,
              child: const Icon(Icons.chat_bubble_rounded)
            ), 
            label: "Chat"
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
      body: pages[_currentIndex],
    );
  }
}

class CaregiverDashboard extends StatelessWidget {
  final int caregiverId;
  final String name;
  final int activeCount;
  final List<Map<String, dynamic>> upcomingVisits;
  final List<Map<String, dynamic>> pendingRequests;
  final Function(int, int) onAction;
  final VoidCallback onRefresh;
  final Color themeColor;

  const CaregiverDashboard({super.key, required this.caregiverId, required this.name, required this.activeCount, required this.upcomingVisits, required this.pendingRequests, required this.onAction, required this.onRefresh, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [themeColor, const Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Active Session,", style: TextStyle(color: Colors.teal[50], fontSize: 13)), Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))]),
                          CircleAvatar(radius: 24, backgroundColor: Colors.white.withOpacity(0.15), child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pendingRequests.isNotEmpty) ...[
                    _sectionHeader("Action Required", Icons.error_outline_rounded, Colors.orange),
                    const SizedBox(height: 12),
                    Column(children: pendingRequests.map((req) => _buildPendingCard(req, context)).toList()),
                    const SizedBox(height: 32),
                  ],
                  _sectionHeader("Your Active Patients", Icons.people_alt_rounded, themeColor),
                  const SizedBox(height: 16),
                  if (upcomingVisits.isEmpty) _emptyState("No patients assigned yet", context)
                  else Column(children: upcomingVisits.map((req) => _buildVisitCard(req['tbl_patient']['patient_name'], "ACTIVE", req['request_details'] ?? "Medical Support", themeColor, context, caregiverId, req['patient_id'])).toList()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))]);
  }

  Widget _statBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
       _statBox("Managed Patients", activeCount.toString(), Icons.people_outline, Colors.white),
       const SizedBox(width: 16),
       _statBox("New Requests", pendingRequests.length.toString(), Icons.notifications_active_outlined, Colors.white),
    ]);
  }

  Widget _buildVisitCard(String patient, String status, String task, Color color, BuildContext context, int caregiverId, int patientId) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PatientDetailsScreen(patientId: patientId, patientName: patient, caregiverId: caregiverId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey[50]!),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.person, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937))), const SizedBox(height: 2), Text(task, style: TextStyle(fontSize: 13, color: Colors.grey[500]))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _emptyState(String text, BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)), child: Column(children: [Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[200]), const SizedBox(height: 12), Text(text, style: TextStyle(color: Colors.grey[400]))]));
  }

  Widget _buildPendingCard(Map<String, dynamic> req, BuildContext context) {
    final patient = req['tbl_patient'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Row(children: [CircleAvatar(radius: 24, backgroundColor: Colors.orange.withOpacity(0.05), child: Text(patient['patient_name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient['patient_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("Requires monitoring", style: TextStyle(fontSize: 12, color: Colors.grey[500]))]))]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => onAction(req['id'], 2), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("DECLINE"))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => onAction(req['id'], 1), style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text("ACCEPT", style: TextStyle(color: Colors.white)))),
          ]),
        ],
      ),
    );
  }
}
