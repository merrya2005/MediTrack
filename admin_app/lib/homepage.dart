import 'package:admin_app/category.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/manage_caretaker.dart';
import 'package:admin_app/manage_patient.dart';
import 'package:admin_app/place.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/complaints.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const District(),
    const Place(),
    const medicinecategory(),
    const ManageCaretakers(),
    const ManagePatient(),
    const AdminComplaintsScreen(),
  ];

  final List<String> _pageTitles = [
    "Dashboard Overview",
    "Manage Districts",
    "Location Management",
    "Medicine Categories",
    "Caretaker Verification",
    "Patient Directory",
    "Resolve Complaints",
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: isMobile ? Drawer(child: _buildSidebar(context)) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                _pageTitles[_selectedIndex < _pageTitles.length ? _selectedIndex : 0],
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF1F2937)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          // Main Body
          Expanded(
            child: Column(
              children: [
                // Top Header (Desktop only)
                if (!isMobile)
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _pageTitles[_selectedIndex < _pageTitles.length ? _selectedIndex : 0],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          backgroundColor: Color(0xFFF3F4F6),
                          child: Icon(Icons.notifications_none_rounded, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(width: 16),
                        _adminUserBadge(),
                      ],
                    ),
                  ),
                // Content Area
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _pages[_selectedIndex < _pages.length ? _selectedIndex : 0],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1024;
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety_rounded, color: Color(0xFF1A73E8), size: 32),
              SizedBox(width: 12),
              Text("MEDITRACK",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildSidebarItem(0, "Dashboard", Icons.dashboard_rounded, isMobile),
                  _buildSidebarItem(1, "Districts", Icons.map_rounded, isMobile),
                  _buildSidebarItem(2, "Places", Icons.location_on_rounded, isMobile),
                  _buildSidebarItem(3, "Medicines", Icons.medication_rounded, isMobile),
                  const Divider(color: Colors.white10, indent: 20, endIndent: 20),
                  _buildSidebarItem(4, "Caretakers", Icons.people_alt_rounded, isMobile),
                  _buildSidebarItem(5, "Patients", Icons.person_search_rounded, isMobile),
                  _buildSidebarItem(6, "Complaints", Icons.report_problem_rounded, isMobile),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            onTap: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon, bool isMobile) {
    bool isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isMobile) Navigator.pop(context);
        },
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _adminUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: Color(0xFF1A73E8), child: Icon(Icons.person, size: 16, color: Colors.white)),
          SizedBox(width: 8),
          Text("Administrator", style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  int _patientCount = 0;
  int _caregiverCount = 0;
  int _pendingRequests = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final patients = await supabase.from('tbl_patient').select('id');
      final caregivers = await supabase.from('tbl_caregiver').select('id').eq('caregiver_status', 1);
      final requests = await supabase.from('tbl_request').select('id').eq('request_status', 0);

      setState(() {
        _patientCount = (patients as List).length;
        _caregiverCount = (caregivers as List).length;
        _pendingRequests = (requests as List).length;
      });
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Insights", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            double cardWidth = (constraints.maxWidth - (constraints.maxWidth > 1200 ? 72 : 24)) / 
                              (constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1));
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _buildStatCard("Total Patients", _patientCount.toString(), Icons.person_outline, Colors.blue, cardWidth),
                _buildStatCard("Active Caregivers", _caregiverCount.toString(), Icons.medical_services_outlined, const Color(0xFF10B981), cardWidth),
                _buildStatCard("Pending Bookings", _pendingRequests.toString(), Icons.pending_actions_rounded, Colors.orange, cardWidth),
                _buildStatCard("System Health", "Optimal", Icons.check_circle_outline, Colors.indigo, cardWidth),
              ],
            );
          }),
          const SizedBox(height: 48),
          const Text("Management Console", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildActionCard(context, "Verify Caregivers", "Review new registration requests", Icons.verified_user),
              _buildActionCard(context, "Security Audit", "View recent system access logs", Icons.security_rounded),
              _buildActionCard(context, "Inventory", "Global medicine stock overview", Icons.inventory_2_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73E8), size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
