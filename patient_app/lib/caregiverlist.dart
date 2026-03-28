import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/my_requests.dart';

class CaregiversListView extends StatefulWidget {
  const CaregiversListView({super.key});

  @override
  State<CaregiversListView> createState() => _CaregiversListViewState();
}

class _CaregiversListViewState extends State<CaregiversListView> {
  List<Map<String, dynamic>> _caregivers = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _places = [];
  String? _selectedDistrict;
  String? _selectedPlace;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
    _fetchData();
  }

  Future<void> _fetchDistricts() async {
    try {
      final data = await supabase.from('tbl_district').select();
      setState(() => _districts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error districts: $e");
    }
  }

  Future<void> _fetchPlaces(String districtId) async {
    try {
      final data = await supabase.from('tbl_place').select().eq('district_id', districtId);
      setState(() => _places = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error places: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      
      // Use a more reliable selection approach
      var query = supabase.from('tbl_caregiver').select('*, tbl_place(*, tbl_district(*))');
      
      if (_selectedPlace != null) {
        query = query.eq('place_id', _selectedPlace!);
      } else if (_selectedDistrict != null) {
        // Filter by the district ID via the place relationship
        query = query.eq('tbl_place.district_id', _selectedDistrict!);
      }

      final data = await query;
      if (mounted) {
        setState(() {
          _caregivers = List<Map<String, dynamic>>.from(data ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching caregivers: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() => _isLoading = true);
    _fetchData();
  }

  Future<void> _requestCaregiver(String caregiverId) async {
    try {
      final user = supabase.auth.currentUser;
      final patientData = await supabase.from('tbl_patient').select('id').eq('patient_email', user!.email!).single();
      
      // Check if already requested
      final existing = await supabase
          .from('tbl_request')
          .select()
          .eq('patient_id', patientData['id'])
          .eq('caregiver_id', caregiverId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request already sent to this caregiver!"), backgroundColor: Colors.orange));
        return;
      }

      await supabase.from('tbl_request').insert({
        'patient_id': patientData['id'],
        'caregiver_id': caregiverId,
        'request_details': 'Regular health checkup and assistance',
        'request_status': 0
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Request error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));

    return Container(
      color: const Color(0xFFF9FAFB),
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF0F766E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildCustomHeader(context)),
            SliverToBoxAdapter(child: _buildFilterBar(context)),
            if (_caregivers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("No caregivers found", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("Try checking another district or place", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cg = _caregivers[index];
                      final place = cg['tbl_place']?['place_name'] ?? 'Unknown Place';
                      final dist = cg['tbl_place']?['tbl_district']?['district_name'] ?? 'Unknown District';
                      return _buildCaregiverCard(cg, place, dist, index);
                    },
                    childCount: _caregivers.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Find Caregivers", 
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text("Professional health support near you", 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.12), shape: BoxShape.circle),
                child: IconButton(
                  onPressed: _fetchData, 
                  icon: const Icon(Icons.sync_rounded, color: Color(0xFF0F766E), size: 24)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _filterActionBtn("MY REQUESTS", Icons.mark_email_unread_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen()))),
          const SizedBox(width: 12),
          _filterDropdown("District", _districts, _selectedDistrict, (val) async {
            setState(() {
              _selectedDistrict = val;
              _selectedPlace = null; 
              _places = [];
            });
            if (val != null) await _fetchPlaces(val);
            _fetchData();
          }),
          const SizedBox(width: 12),
          _filterDropdown("Place", _places, _selectedPlace, (val) {
            setState(() => _selectedPlace = val);
            _fetchData();
          }),
        ],
      ),
    );
  }

  Widget _filterActionBtn(String label, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF0F766E).withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _filterDropdown(String label, List<Map<String, dynamic>> items, String? value, Function(String?) onChanged) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563))),
          value: value,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(20),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF0F766E)),
          items: [
            DropdownMenuItem<String>(value: null, child: Text("All $label", style: GoogleFonts.outfit(fontSize: 13))),
            ...items.map((item) => DropdownMenuItem<String>(
              value: item['id']?.toString(), 
              child: Text(item['district_name'] ?? item['place_name'] ?? "", style: GoogleFonts.outfit(fontSize: 13), overflow: TextOverflow.ellipsis)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(Map<String, dynamic> cg, String place, String dist, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // Constraint width to prevent overflows
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Hero(
                  tag: 'cg-${cg['id'] ?? index}', // Fallback if id is null
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF0F766E).withOpacity(0.1),
                      image: cg['caregiver_photo'] != null && cg['caregiver_photo'].toString().isNotEmpty 
                        ? DecorationImage(image: NetworkImage(cg['caregiver_photo']), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: (cg['caregiver_photo'] == null || cg['caregiver_photo'].toString().isEmpty) 
                      ? const Icon(Icons.person, size: 30, color: Color(0xFF0F766E)) 
                      : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cg['caregiver_name'] ?? "Unknown", 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF111827))),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                              child: Text("${cg['caregiver_experience'] ?? '0'} Years Exp", 
                                style: GoogleFonts.outfit(color: const Color(0xFF0F766E), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                            const SizedBox(width: 2),
                            Text("4.9", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF14B8A6), size: 14),
                          const SizedBox(width: 3),
                          Expanded(child: Text("$place, $dist", overflow: TextOverflow.ellipsis, 
                            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _requestCaregiver(cg['id'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text("Request", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
