import 'package:flutter/material.dart';

class CaregiversListView extends StatelessWidget {
  const CaregiversListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Caregivers
    final List<Map<String, String>> caregivers = [
      {
        "name": "Alice Smith",
        "role": "Primary Caregiver",
        "phone": "+1 234 567",
      },
      {
        "name": "Dr. Robert Wilson",
        "role": "Physical Therapist",
        "phone": "+1 987 654",
      },
      {
        "name": "Sarah Parker",
        "role": "Family (Daughter)",
        "phone": "+1 555 019",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: caregivers.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.teal.shade50,
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(
              caregivers[index]['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(caregivers[index]['role']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message_outlined, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
