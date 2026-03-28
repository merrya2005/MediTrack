import 'package:flutter/material.dart';
import 'package:patient_app/main.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class NotificationsScreen extends StatefulWidget {
  final int patientId;
  const NotificationsScreen({super.key, required this.patientId});

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

      // 1. Fetch Unread Messages (Minimal Select to avoid ambiguity)
      final msgs = await supabase.from('tbl_chat').select('id, chat_content, created_at').eq('chat_topatient', widget.patientId).eq('chat_isseen', 0);
      for (var m in msgs) {
        temp.add({
          'id': 'msg_${m['id']}',
          'title': "New Message",
          'body': m['chat_content'],
          'type': 'chat',
          'time': DateTime.parse(m['created_at']),
        });
      }

      // 2. Fetch Low Stock
      final meds = await supabase.from('tbl_medicine').select('id, medicine_name').eq('patient_id', widget.patientId);
      final medIds = meds.map((m) => m['id']).toList();
      if (medIds.isNotEmpty) {
        final stock = await supabase.from('tbl_stock').select('stock_count, medicine_id').filter('medicine_id', 'in', medIds);
        for (var s in stock) {
          if (s['stock_count'] <= 5) {
            final medName = meds.firstWhere((m) => m['id'] == s['medicine_id'])['medicine_name'];
            temp.add({
              'id': 'stock_${s['medicine_id']}',
              'title': "Low Stock Alert!",
              'body': "$medName has only ${s['stock_count']} left.",
              'type': 'stock',
              'time': DateTime.now(),
            });
          }
        }
      }

      // 3. Fetch Missed Medications
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final currentHourMin = DateFormat('HH:mm').format(now);

      for (var med in meds) {
        final medData = await supabase.from('tbl_medicine').select().eq('id', med['id']).single();
        if (medData['medicine_time'] != null && medData['medicine_time'].toString().compareTo(currentHourMin) < 0) {
           final logs = await supabase.from('tbl_intake_log').select().eq('medicine_id', med['id']).gte('intake_datetime', todayStr);
           if (logs.isEmpty) {
             temp.add({
               'id': 'med_${med['id']}',
               'title': "Missed Dose",
               'body': "You missed your ${medData['medicine_time']} dose of ${medData['medicine_name']}.",
               'type': 'med',
               'time': now,
             });
           }
        }
      }

      temp.sort((a, b) => b['time'].compareTo(a['time']));
      if (mounted) setState(() { _notifications = temp; _isLoading = false; });
    } catch (e) {
      if (e is SocketException || e.toString().contains("Failed host lookup")) {
         debugPrint("Noti sync: Network issue.");
      } else {
         debugPrint("Noti error: $e");
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    try {
      await supabase.from('tbl_chat').update({'chat_isseen': 1}).eq('chat_topatient', widget.patientId).eq('chat_isseen', 0);
      _fetchNotifications();
    } catch (e) { debugPrint("Clear error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Notifications"),
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
    if (n['type'] == 'med') { icon = Icons.alarm; color = const Color(0xFF0F766E); }
    else if (n['type'] == 'stock') { icon = Icons.inventory_2_rounded; color = Colors.orange; }
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
