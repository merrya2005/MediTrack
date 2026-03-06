import 'package:flutter/material.dart';

class AdminReg extends StatefulWidget {
  const AdminReg({super.key});

  @override
  State<AdminReg> createState() => _AdminRegState();
}

class _AdminRegState extends State<AdminReg> {
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person, color: Colors.blue),
        title: Text(
          "Login page",
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
                label: Text("Password"),
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.password),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
