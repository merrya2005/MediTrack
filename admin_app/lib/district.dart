import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  TextEditingController districtController = TextEditingController();
  Future<void> insert() async {
    String district = districtController.text;
    try {
      await supabase.from('tbl_district').insert({'district_name': district});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("District added succesfully")));
    } catch (e) {
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person, color: Colors.blue),
        title: Text(
          "Admin page",
          style: TextStyle(color: Colors.blueGrey, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                controller: districtController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("District"),
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  insert();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: OvalBorder(),
                ),
                child: Text("SUBMIT", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
