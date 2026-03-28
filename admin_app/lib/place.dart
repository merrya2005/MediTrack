import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  final TextEditingController _placeController = TextEditingController();
  List<Map<String, dynamic>> placeList = [];
  List<Map<String, dynamic>> districtList = [];
  bool _isLoading = false;
  int? editId;
  int? selectedDistrictId;

  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    try {
      final districts = await supabase
          .from('tbl_district')
          .select()
          .order('district_name', ascending: true);
      
      final places = await supabase
          .from('tbl_place')
          .select('*, tbl_district(district_name)')
          .order('place_name', ascending: true);

      setState(() {
        districtList = List<Map<String, dynamic>>.from(districts);
        placeList = List<Map<String, dynamic>>.from(places);
      });
    } catch (e) {
      debugPrint("ERROR FETCHING DATA: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleSubmit() async {
    if (_placeController.text.isEmpty || selectedDistrictId == null) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (editId == null) {
        await supabase.from('tbl_place').insert({
          'place_name': _placeController.text,
          'district_id': selectedDistrictId,
        });
        _showSnackBar("Place Added Successfully", Colors.green);
      } else {
        await supabase.from('tbl_place').update({
          'place_name': _placeController.text,
          'district_id': selectedDistrictId,
        }).eq('id', editId!);
        _showSnackBar("Place Updated Successfully", Colors.blue);
      }
      _placeController.clear();
      setState(() {
        editId = null;
        selectedDistrictId = null;
      });
      fetchData();
    } catch (e) {
      debugPrint("ERROR SUBMITTING PLACE: $e");
      _showSnackBar("Error occurred", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deletePlace(int id) async {
    try {
      await supabase.from("tbl_place").delete().eq("id", id);
      _showSnackBar("Place Deleted", Colors.orange);
      fetchData();
    } catch (e) {
      debugPrint("ERROR DELETING PLACE: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // Sidebar Form
          Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editId == null ? "Add Place" : "Edit Place",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Assign places to districts for better mapping.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<int>(
                  value: selectedDistrictId,
                  decoration: const InputDecoration(
                    labelText: "Select District",
                  ),
                  items: districtList.map((district) {
                    return DropdownMenuItem<int>(
                      value: district['id'],
                      child: Text(district['district_name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDistrictId = val),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _placeController,
                  decoration: const InputDecoration(
                    labelText: "Place Name",
                    hintText: "Enter place name",
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(editId == null ? "Save Place" : "Update Place"),
                ),
                if (editId != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        editId = null;
                        selectedDistrictId = null;
                        _placeController.clear();
                      });
                    },
                    child: const Text("Cancel Edit"),
                  ),
                ],
              ],
            ),
          ),
          // Content List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Place Directory",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: fetchData,
                        icon: const Icon(Icons.refresh),
                        tooltip: "Refresh List",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoading && placeList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: placeList.isEmpty
                                ? const Center(child: Text("No places found"))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: placeList.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final place = placeList[index];
                                      return ListTile(
                                        title: Text(
                                          place['place_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Text(
                                          place['tbl_district']?['district_name'] ?? 'No District',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                setState(() {
                                                  _placeController.text =
                                                      place['place_name'];
                                                  editId = place['id'];
                                                  selectedDistrictId = place['district_id'];
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.red),
                                              onPressed: () => deletePlace(
                                                  place['id']),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
