import 'package:admin_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  bool _isFormVisible = false;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  final TextEditingController _PlaceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  List<Map<String, dynamic>> placeList = [];

  Future<void> insertPlace() async {
    try {
      String name = _PlaceController.text;
      await supabase.from('tbl_place').insert({'place_name': name});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Place Added Successfully",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      fetchPlace();
      _PlaceController.clear();
    } catch (e) {
      print("ERROR INSERTING DATA: $e");
    }
  }

  Future<void> fetchPlace() async {
    try {
      final response = await supabase.from('tbl_place').select();
      setState(() {
        placeList = response;
      });
    } catch (e) {
      print("ERROR FETCHING DATA: $e");
    }
  }

  int did = 0;

  Future<void> editPlace() async {
    try {
      await supabase
          .from('tbl_place')
          .update({'place_name': _PlaceController.text})
          .eq('id', did);
      fetchPlace();
      _PlaceController.clear();
    } catch (e) {
      print("ERROR UPDATING DATA: $e");
    }
  }

  Future<void> deletePlace(String did) async {
    try {
      await supabase.from("tbl_place").delete().eq("id", did);
      fetchPlace();
    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPlace();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Manage Places",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF161616),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                ),
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible;
                    if (!_isFormVisible) {
                      _PlaceController.clear();
                      did = 0;
                    }
                  });
                },
                label: Text(
                  _isFormVisible ? "Cancel" : "Add Place",
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(
                  _isFormVisible ? Icons.cancel : Icons.add,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            labelText: "District Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _PlaceController,
                          decoration: InputDecoration(
                            labelText: "Place Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          if (_isFormVisible)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                if (did == 0) {
                  insertPlace();
                } else {
                  editPlace();
                }
              },
              child: Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          SizedBox(height: 20),
          Text(
            "Places ",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Sl No")),
                  DataColumn(label: Text("Place Name")),
                  DataColumn(label: Text("Action")),
                ],
                rows: placeList.asMap().entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text((entry.key + 1).toString())),
                      DataCell(Text(entry.value['place_name'])),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deletePlace(entry.value['id'].toString());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _PlaceController.text =
                                      entry.value['place_name'];
                                  did = entry.value['id'];
                                  _isFormVisible = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
