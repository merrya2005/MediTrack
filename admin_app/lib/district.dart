import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  bool _isFormVisible = false;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  final TextEditingController _districtController = TextEditingController();

  List<Map<String, dynamic>> districtList = [];

  Future<void> insertDistrict() async {
    try {
      String name = _districtController.text;
      await supabase.from('tbl_district').insert({'district_name': name});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "District Added Successfully",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      fetchDistricts();
      _districtController.clear();
    } catch (e) {
      print("ERROR INSERTING DATA: $e");
    }
  }

  Future<void> fetchDistricts() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() {
        districtList = response;
      });
    } catch (e) {
      print("ERROR FETCHING DATA: $e");
    }
  }

  int did = 0;

  Future<void> editDistrict() async {
    try {
      await supabase
          .from('tbl_district')
          .update({'district_name': _districtController.text})
          .eq('id', did);
      fetchDistricts();
      _districtController.clear();
    } catch (e) {
      print("ERROR UPDATING DATA: $e");
    }
  }

  Future<void> deleteDistrict(String did) async {
    try {
      await supabase.from("tbl_district").delete().eq("id", did);
      fetchDistricts();
    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDistricts();
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
                "Manage Districts",
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
                      _districtController.clear();
                      did = 0;
                    }
                  });
                },
                label: Text(
                  _isFormVisible ? "Cancel" : "Add District",
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
                    child: TextField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: "District Name",
                        border: OutlineInputBorder(),
                      ),
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
                  insertDistrict();
                } else {
                  editDistrict();
                }
              },
              child: Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          SizedBox(height: 20),
          Text(
            "Districts ",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Sl No")),
                  DataColumn(label: Text("District Name")),
                  DataColumn(label: Text("Action")),
                ],
                rows: districtList.asMap().entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text((entry.key + 1).toString())),
                      DataCell(Text(entry.value['district_name'])),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteDistrict(entry.value['id'].toString());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _districtController.text =
                                      entry.value['district_name'];
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
