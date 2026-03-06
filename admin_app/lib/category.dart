import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  TextEditingController categoryController = TextEditingController();

  Future<void> insert() async {
    String category = categoryController.text;
    try {
      await supabase.from('tbl_category').insert({'category_name': category});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Category added succesfully")));
    } catch (e) {
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person, color: Colors.yellow),
        title: Text(
          "Admin page",
          style: TextStyle(color: Colors.blueGrey, fontSize: 20),
        ),
      ),

      body: Form(
        child: Column(
          children: [
            TextFormField(
              controller: categoryController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Category"),
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
    );
  }
}
