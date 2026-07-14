import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminTodayAppointmentsScreen extends StatefulWidget {
  const AdminTodayAppointmentsScreen({super.key});

  @override
  State<AdminTodayAppointmentsScreen> createState() => _AdminTodayAppointmentsScreenState();
}

class _AdminTodayAppointmentsScreenState extends State<AdminTodayAppointmentsScreen> {
  String _searchQuery = "";
  String _selectedShift = "All"; // "All", "Morning", "Afternoon", "Evening"
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchTodayAppointments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "Chưa rõ";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return "Chưa rõ";
    }
  }

  List<dynamic> _applyFilters(List<dynamic> rawList) {
    return rawList.where((item) {
      // 1. Lọc theo tìm kiếm
      final doctorName = (item['Ten_bac_si'] ?? '').toString().toLowerCase();
      final bookingCode = (item['Ma_booking'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      final matchSearch = query.isEmpty || doctorName.contains(query) || bookingCode.contains(query);

      // 2. Lọc theo ca khám
      bool matchShift = true;
      if (_selectedShift != "All") {
        final timeStr = item['Thoi_gian_Bdau'];
        if (timeStr != null) {
          try {
            final hour = DateTime.parse(timeStr).toLocal().hour;
            if (_selectedShift == "Morning") {
              matchShift = (hour >= 8 && hour < 12); 
            } else if (_selectedShift == "Afternoon") {
              matchShift = (hour >= 12 && hour < 18); 
            } else if (_selectedShift == "Evening") {
              matchShift = (hour >= 18); 
            }
          } catch (e) {
            matchShift = false;
          }
        } else {
          matchShift = false;
        }
      }

      return matchSearch && matchShift;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final rawList = adminVM.todayAppointments;

    final filteredList = _applyFilters(rawList);

    final pendingList = filteredList.where((item) => 
        item['Trang_thai_lich_hen'] == 'confirmed' || 
        item['Trang_thai_lich_hen'] == 'pending' || 
        item['Trang_thai_lich_hen'] == 'reschedule_pending').toList();

    final doneList = filteredList.where((item) => item['Trang_thai_lich_hen'] == 'done').toList();
    final cancelledList = filteredList.where((item) => item['Trang_thai_lich_hen'] == 'cancelled' || item['Trang_thai_lich_hen'] == 'absent').toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: kLightCyanBg2,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text('Lịch Hẹn Hôm Nay', style: kHeaderTextStyle),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ duyệt / Chờ khám / Chờ dời lịch'),
              Tab(text: 'Đã hoàn thành'),
              Tab(text: 'Đã hủy / Vắng mặt'),
            ],
          ),
        ),
        body: adminVM.isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : Column(
                children: [
                  _buildFilterSection(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAppointmentListView(filteredList),
                        _buildAppointmentListView(pendingList),
                        _buildAppointmentListView(doneList),
                        _buildAppointmentListView(cancelledList),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo Mã booking hoặc Tên bác sĩ...',
              hintStyle: const TextStyle(color: kGreyTextColor, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _searchQuery = ""; });
                      },
                    ) 
                  : null,
              filled: true,
              fillColor: kLightCyanBg1,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildShiftChip("Tất cả ca", "All"),
                const SizedBox(width: 8),
                _buildShiftChip("Sáng (8h-12h)", "Morning"),
                const SizedBox(width: 8),
                _buildShiftChip("Chiều (13h-17h)", "Afternoon"),
                const SizedBox(width: 8),
                _buildShiftChip("Tối (18h-21h)", "Evening"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftChip(String label, String shiftValue) {
    final isSelected = _selectedShift == shiftValue;
    return ChoiceChip(
      label: Text(
        label, 
        style: TextStyle(
          color: isSelected ? Colors.white : kTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13
        )
      ),
      selected: isSelected,
      selectedColor: kPrimaryColor,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
      showCheckmark: false,
      onSelected: (bool selected) {
        setState(() {
          _selectedShift = shiftValue;
        });
      },
    );
  }

  Widget _buildAppointmentListView(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Không có ca khám nào khớp với tìm kiếm.',
          style: TextStyle(color: kGreyTextColor, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () async => context.read<AdminViewModel>().fetchTodayAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final String status = item['Trang_thai_lich_hen'] ?? 'pending';
          
          final String hocVi = (item['Hoc_vi'] != null && item['Hoc_vi'].toString().isNotEmpty) 
              ? item['Hoc_vi'] 
              : 'BS.'; 
          final String tenBacSi = item['Ten_bac_si'] ?? 'Chưa rõ';
          final String fullNameDoctor = "$hocVi $tenBacSi"; 

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              border: Border.all(color: kBorderCyan),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${_formatTime(item['Thoi_gian_Bdau'])} - ${_formatTime(item['Thoi_gian_Kthuc'])}',
                        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: kBorderCyan),
                ),
                _buildInfoRow(Icons.confirmation_number_outlined, "Mã booking:", item['Ma_booking'] ?? 'Chưa rõ', textColor: Colors.black87),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, "Bệnh nhân:", item['Ten_benh_nhan'] ?? 'Chưa rõ'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.medical_information, "Bác sĩ phụ trách:", fullNameDoctor),
                const SizedBox(height: 8),
                _buildInfoRow(
                  item['Hinh_thuc'] == 'online' ? Icons.videocam : Icons.location_on, 
                  "Hình thức:", 
                  item['Hinh_thuc'] == 'online' ? "Khám Trực Tuyến (Video Call)" : "Khám Trực Tiếp tại Clinic",
                  textColor: item['Hinh_thuc'] == 'online' ? Colors.blue : Colors.redAccent
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.medical_services_outlined, "Dịch vụ chỉ định:", item['Ten_dich_vu'] ?? 'Khám tổng quát / khám lâm sàng'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kGreyTextColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 14)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor ?? kTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor; Color textColor; String text;
    switch (status) {
      case 'confirmed': bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Chờ khám'; break;
      case 'done': bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Hoàn thành'; break;
      case 'cancelled': bgColor = Colors.red.shade50; textColor = Colors.red; text = 'Đã hủy'; break;
      case 'absent': bgColor = Colors.grey.shade100; textColor = Colors.grey; text = 'Vắng mặt'; break;
      case 'reschedule_pending': bgColor = Colors.orange.shade50; textColor = Colors.orange.shade900; text = 'Chờ dời lịch'; break;
      default: bgColor = Colors.orange.shade50; textColor = Colors.orange; text = 'Chờ duyệt'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}