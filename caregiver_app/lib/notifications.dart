import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class NotificationsScreen extends StatefulWidget {
  final int caregiverId;
  const NotificationsScreen({super.key, required this.caregiverId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      List<Map<String, dynamic>> temp = [];

      // 1. Fetch Unread Messages (EXPLICIT SELECT - NO AMBIGUITY)
      // We explicitly name the relationship for the embed
      final msgs = await supabase
          .from('tbl_chat')
          .select('id, chat_content, created_at, tbl_patient!tbl_chat_chat_frompatient_fkey(patient_name)')
          .eq('chat_tocaregiver', widget.caregiverId)
          .eq('chat_isseen', 0);
          
      for (var m in msgs) {
        final pData = m['tbl_patient!tbl_chat_chat_frompatient_fkey'];
        temp.add({
          'id': 'msg_${m['id']}',
          'title': "Message from ${pData?['patient_name'] ?? 'Patient'}",
          'body': m['chat_content'],
          'type': 'chat',
          'time': DateTime.parse(m['created_at']),
        });
      }

      // 2. Fetch Pending Requests
      final requests = await supabase.from('tbl_request').select('*, tbl_patient(patient_name)').eq('caregiver_id', widget.caregiverId).eq('request_status', 0);
      for (var r in requests) {
        temp.add({
          'id': 'req_${r['id']}',
          'title': "New Partner Request",
          'body': "${r['tbl_patient']?['patient_name']} sent you a request to be their partner.",
          'type': 'req',
          'time': DateTime.parse(r['created_at']),
        });
      }

      // 3. Fetch Missed Medications (Alert for caregiver)
      final active = await supabase.from('tbl_request').select('*, tbl_patient(*)').eq('caregiver_id', widget.caregiverId).eq('request_status', 1);
      final patientIds = active.map((r) => r['patient_id']).toList();
      if (patientIds.isNotEmpty) {
        final meds = await supabase.from('tbl_medicine').select('*, tbl_patient(patient_name)').filter('patient_id', 'in', patientIds);
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final currentHourMin = DateFormat('HH:mm').format(now);

        for (var med in meds) {
          if (med['medicine_time'] != null && med['medicine_time'].toString().compareTo(currentHourMin) < 0) {
             final logs = await supabase.from('tbl_intake_log').select().eq('medicine_id', med['id']).gte('intake_datetime', todayStr);
             if (logs.isEmpty) {
               temp.add({
                 'id': 'miss_${med['id']}',
                 'title': "URGENT: Missed Med",
                 'body': "${med['tbl_patient']['patient_name']} missed their ${med['medicine_time']} dose of ${med['medicine_name']}.",
                 'type': 'med',
                 'time': now,
               });
             }
          }
        }
      }

      temp.sort((a, b) => b['time'].compareTo(a['time']));
      if (mounted) setState(() { _notifications = temp; _isLoading = false; });
    } catch (e) {
      if (e is SocketException || e.toString().contains("Failed host lookup")) {
         debugPrint("Noti sync: Waiting for network...");
      } else {
         debugPrint("Noti error: $e");
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    try {
      await supabase.from('tbl_chat').update({'chat_isseen': 1}).eq('chat_tocaregiver', widget.caregiverId).eq('chat_isseen', 0);
      _fetchNotifications();
    } catch (e) { debugPrint("Clear error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Notifications Center"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty) TextButton(onPressed: _clearAll, child: const Text("Clear All", style: TextStyle(color: Color(0xFF0F766E)))),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty 
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return _notiCard(n);
                },
              ),
            ),
    );
  }

  Widget _notiCard(Map<String, dynamic> n) {
    IconData icon = Icons.notifications;
    Color color = Colors.blue;
    if (n['type'] == 'med') { icon = Icons.warning_amber_rounded; color = const Color(0xFF0F766E); }
    else if (n['type'] == 'req') { icon = Icons.person_add_rounded; color = Colors.orange; }
    else if (n['type'] == 'chat') { icon = Icons.chat_bubble_rounded; color = const Color(0xFF0F766E); }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(DateFormat('HH:mm').format(n['time']), style: TextStyle(color: Colors.grey[400], fontSize: 10))]),
            const SizedBox(height: 6),
            Text(n['body'], style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
          ])),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text("No notifications yet", style: TextStyle(color: Colors.grey[400]))]));
  }
}
