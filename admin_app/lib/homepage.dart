import 'package:admin_app/login.dart';
import 'package:admin_app/manage_caretaker.dart';
import 'package:admin_app/manage_patient.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // This index controls which page is currently visible
  int _selectedIndex = 0;

  void _handleLogout() {
    debugPrint("User Logged Out");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // --- PAGE LIST ---
  // Ensure this list order matches the order of your sidebar items
  final List<Widget> _pages = [
    const DashboardOverview(), // See the helper class created below
    const ManageCaretakers(),
    const ManagePatients(),
    const Center(
      child: Text("Activity Logs Content", style: TextStyle(fontSize: 18)),
    ),
  ];

  final List<String> _pageTitles = [
    "Dashboard",
    "Caretaker Management",
    "Patient Records",
    "System Logs",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // 1. SIDEBAR (Navigation Trigger)
          _buildSidebar(),

          // 2. MAIN CONTENT (Navigation Target)
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      key: ValueKey<int>(
                        _selectedIndex,
                      ), // Helps with smooth transitions
                      padding: const EdgeInsets.all(24.0),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 80,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: Colors.teal, size: 28),
                SizedBox(width: 12),
                Text(
                  "MediTrack",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 20),

          _buildMenuItem(0, "Dashboard", Icons.grid_view_rounded),
          _buildMenuItem(1, "Caretakers", Icons.badge_outlined),
          _buildMenuItem(2, "Patients", Icons.person_search_rounded),
          _buildMenuItem(3, "Activity Logs", Icons.history_rounded),

          const Spacer(),
          ListTile(
            onTap: _handleLogout,
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.teal.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        setState(() {
          _selectedIndex =
              index; // This triggers the build method to show the new page
        });
      },
      leading: Icon(icon, color: isSelected ? Colors.teal : Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.teal : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Text(
            _pageTitles[_selectedIndex],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Row(
            children: [
              Text("Admin User", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Color(0xFFE0F2F1),
                child: Icon(Icons.person, color: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- QUICK DASHBOARD OVERVIEW WIDGET ---
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard("Total Patients", "124", Icons.person, Colors.blue),
        _buildStatCard("Active Caretakers", "42", Icons.badge, Colors.teal),
        _buildStatCard("Alerts Today", "5", Icons.warning_amber, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
