import 'package:flutter/material.dart';

class password extends StatefulWidget {
  const password({super.key});

  @override
  State<password> createState() => _passwordState();
}

class _passwordState extends State<password> {
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
                label: Text("Old Password"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.password),
              ),
            ),

            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("New Password"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.password),
              ),
            ),

            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Confirm Password"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.password),
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
