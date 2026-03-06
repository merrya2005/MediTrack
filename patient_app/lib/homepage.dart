import 'package:flutter/material.dart';
import 'package:patient_app/caregiverlist.dart';
import 'package:patient_app/profile.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  // Navigation Pages
  final List<Widget> _pages = [
    const PatientDashboard(),
    const CaregiversListView(),
    const Center(child: Text("Health Logs & Reports")),
    const PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_graph_rounded, color: Colors.teal),
            const SizedBox(width: 10),
            const Text(
              "MediTrack+",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.teal,
            ),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: "Caregivers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Health",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}

// ==========================================
// 1. DASHBOARD TAB
// ==========================================
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome back,",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Text(
            "Grandpa John",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Medicine Reminder Card
          _buildMedsCard(),
          const SizedBox(height: 25),

          const Text(
            "Daily Health Goals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildHealthGrid(),
        ],
      ),
    );
  }

  Widget _buildMedsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: const NetworkImage(
            "https://www.transparenttextures.com/patterns/cubes.png",
          ),
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.medication, color: Colors.white, size: 40),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Next Medicine in 45m",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Donepezil - 5mg (Post Lunch)",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                  shape: StadiumBorder(),
                ),
                child: const Text("TAKE"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _statItem("Blood Pressure", "120/80", Icons.favorite, Colors.red),
        _statItem("Step Count", "3,420", Icons.directions_walk, Colors.blue),
        _statItem("Heart Rate", "72 bpm", Icons.monitor_heart, Colors.orange),
        _statItem("Sleep", "7h 20m", Icons.bedtime, Colors.indigo),
      ],
    );
  }

  Widget _statItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ==========================================
// 2. CAREGIVERS VIEW TAB
// ==========================================

// ==========================================
// 3. PROFILE & LOGOUT TAB
// ==========================================

// Helper extension for clean ElevatedButton syntax
extension on ButtonStyle {
  Widget childWidget({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(onPressed: onPressed, style: this, child: child);
  }
}
