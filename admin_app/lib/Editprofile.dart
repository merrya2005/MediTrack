import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person, color: Colors.blue),
        title: Text(
          "Admin page",
          style: TextStyle(color: Colors.blueGrey, fontSize: 20),
        ),
      ),

      body: Form(
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Name"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.badge),
              ),
            ),

            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Email"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Contact"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Address"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: ContinuousRectangleBorder(),
              ),
              child: Text("SUBMIT", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
