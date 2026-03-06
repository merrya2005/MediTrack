import 'package:flutter/material.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 15),
          const Text(
            "Grandpa John",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Patient ID: #MT-9981",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),

          _profileTile("Personal Details", Icons.badge_outlined),
          _profileTile("Medical History", Icons.history_edu_outlined),
          _profileTile("Emergency Contacts", Icons.contact_emergency_outlined),
          _profileTile("App Settings", Icons.settings_outlined),

          const SizedBox(height: 30),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).childWidget(
                  onPressed: () {
                    // Handle Logout Logic
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text(
                        "LOGOUT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}

extension on ButtonStyle {
  Widget? childWidget({
    required Null Function() onPressed,
    required Row child,
  }) {}
}
