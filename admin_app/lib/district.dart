import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  final TextEditingController _districtController = TextEditingController();
  List<Map<String, dynamic>> districtList = [];
  bool _isLoading = false;
  int? editId;

  Future<void> fetchDistricts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_district')
          .select()
          .order('district_name', ascending: true);
      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("ERROR FETCHING DISTRICTS: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleSubmit() async {
    if (_districtController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (editId == null) {
        await supabase
            .from('tbl_district')
            .insert({'district_name': _districtController.text});
        _showSnackBar("District Added Successfully", Colors.green);
      } else {
        await supabase
            .from('tbl_district')
            .update({'district_name': _districtController.text})
            .eq('id', editId!);
        _showSnackBar("District Updated Successfully", Colors.blue);
      }
      _districtController.clear();
      setState(() => editId = null);
      fetchDistricts();
    } catch (e) {
      debugPrint("ERROR SUBMITTING DISTRICT: $e");
      _showSnackBar("Error occurred", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteDistrict(int id) async {
    try {
      await supabase.from("tbl_district").delete().eq("id", id);
      _showSnackBar("District Deleted", Colors.orange);
      fetchDistricts();
    } catch (e) {
      debugPrint("ERROR DELETING DISTRICT: $e");
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
    fetchDistricts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // Sidebar-like Form
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
                  editId == null ? "Add District" : "Edit District",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage geographic districts for categorization.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: "District Name",
                    hintText: "Enter district name",
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
                      : Text(editId == null ? "Save District" : "Update District"),
                ),
                if (editId != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        editId = null;
                        _districtController.clear();
                      });
                    },
                    child: const Text("Cancel Edit"),
                  ),
                ],
              ],
            ),
          ),
          // Main Content List
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
                        "District Directory",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: fetchDistricts,
                        icon: const Icon(Icons.refresh),
                        tooltip: "Refresh List",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoading && districtList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: districtList.isEmpty
                                ? const Center(child: Text("No districts found"))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: districtList.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final district = districtList[index];
                                      return ListTile(
                                        title: Text(
                                          district['district_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                setState(() {
                                                  _districtController.text =
                                                      district['district_name'];
                                                  editId = district['id'];
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.red),
                                              onPressed: () => deleteDistrict(
                                                  district['id']),
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
