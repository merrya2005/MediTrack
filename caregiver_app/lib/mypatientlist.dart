import 'package:flutter/material.dart';

class MyPatientsList extends StatelessWidget {
  const MyPatientsList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> patients = [
      {"name": "Grandpa John", "age": "78", "condition": "Post-Surgery"},
      {"name": "Alice Smith", "age": "65", "condition": "Diabetes"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              patients[index]['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${patients[index]['condition']} (Age: ${patients[index]['age']})",
            ),
          ),
        );
      },
    );
  }
}
