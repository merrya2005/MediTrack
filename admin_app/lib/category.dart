import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class medicinecategory extends StatefulWidget {
  const medicinecategory({super.key});

  @override
  State<medicinecategory> createState() => _medicinecategoryState();
}

class _medicinecategoryState extends State<medicinecategory> {
  final TextEditingController _categoryController = TextEditingController();
  List<Map<String, dynamic>> categoryList = [];
  bool _isLoading = false;
  int? editId;

  Future<void> fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_medicinecategory')
          .select()
          .order('medicinecategory_name', ascending: true);
      setState(() {
        categoryList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("ERROR FETCHING CATEGORIES: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleSubmit() async {
    if (_categoryController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (editId == null) {
        await supabase
            .from('tbl_medicinecategory')
            .insert({'medicinecategory_name': _categoryController.text});
        _showSnackBar("Category Added Successfully", Colors.green);
      } else {
        await supabase
            .from('tbl_medicinecategory')
            .update({'medicinecategory_name': _categoryController.text})
            .eq('id', editId!);
        _showSnackBar("Category Updated Successfully", Colors.blue);
      }
      _categoryController.clear();
      setState(() => editId = null);
      fetchCategories();
    } catch (e) {
      debugPrint("ERROR SUBMITTING CATEGORY: $e");
      _showSnackBar("Error occurred", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await supabase.from("tbl_medicinecategory").delete().eq("id", id);
      _showSnackBar("Category Deleted", Colors.orange);
      fetchCategories();
    } catch (e) {
      debugPrint("ERROR DELETING CATEGORY: $e");
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
    fetchCategories();
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
                  editId == null ? "Add Category" : "Edit Category",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Define medicine categories for inventory management.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: "Category Name",
                    hintText: "e.g. Antibiotics, Painkillers",
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
                      : Text(editId == null ? "Save Category" : "Update Category"),
                ),
                if (editId != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        editId = null;
                        _categoryController.clear();
                      });
                    },
                    child: const Text("Cancel Edit"),
                  ),
                ],
              ],
            ),
          ),
          // List View
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
                        "Category Directory",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: fetchCategories,
                        icon: const Icon(Icons.refresh),
                        tooltip: "Refresh List",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoading && categoryList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: categoryList.isEmpty
                                ? const Center(child: Text("No categories found"))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: categoryList.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final category = categoryList[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue[50],
                                          child: const Icon(Icons.category_outlined,
                                              color: Colors.blue, size: 20),
                                        ),
                                        title: Text(
                                          category['medicinecategory_name'],
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
                                                  _categoryController.text =
                                                      category['medicinecategory_name'];
                                                  editId = category['id'];
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.red),
                                              onPressed: () => deleteCategory(
                                                  category['id']),
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
