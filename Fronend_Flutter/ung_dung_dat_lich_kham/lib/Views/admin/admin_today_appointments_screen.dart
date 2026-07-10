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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchTodayAppointments();
    });
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

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final allList = adminVM.todayAppointments;

    // Phân loại danh sách theo trạng thái thực tế trong DB của bạn
    final pendingList = allList.where((item) => item['Trang_thai_lich_hen'] == 'confirmed' || item['Trang_thai_lich_hen'] == 'pending').toList();
    final doneList = allList.where((item) => item['Trang_thai_lich_hen'] == 'done').toList();
    final cancelledList = allList.where((item) => item['Trang_thai_lich_hen'] == 'cancelled' || item['Trang_thai_lich_hen'] == 'absent').toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: kLightCyanBg2, // Nền sáng mịn đồng bộ hệ thống
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Lịch Hẹn Hôm Nay', style: kHeaderTextStyle),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ duyệt / Chờ khám'),
              Tab(text: 'Đã hoàn thành'),
              Tab(text: 'Đã hủy / Vắng mặt'),
            ],
          ),
        ),
        body: adminVM.isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : TabBarView(
                children: [
                  _buildAppointmentListView(allList),
                  _buildAppointmentListView(pendingList),
                  _buildAppointmentListView(doneList),
                  _buildAppointmentListView(cancelledList),
                ],
              ),
      ),
    );
  }

  Widget _buildAppointmentListView(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Không có ca khám nào trong danh mục này.',
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
          
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo tròn 20 chuẩn UI nhóm
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
                _buildInfoRow(Icons.medical_information, "Bác sĩ phụ trách:", "BS. ${item['Ten_bac_si'] ?? 'Chưa rõ'}"),
                const SizedBox(height: 8),
                _buildInfoRow(
                  item['Hinh_thuc'] == 'online' ? Icons.videocam : Icons.location_on, 
                  "Hình thức:", 
                  item['Hinh_thuc'] == 'online' ? "Khám Trực Tuyến (Video Call)" : "Khám Trực Tiếp tại Clinic",
                  textColor: item['Hinh_thuc'] == 'online' ? Colors.blue : Colors.redAccent
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.medical_services_outlined, "Dịch vụ chỉ định:", item['Ten_dich_vu'] ?? 'Khám tổng quát khám lâm sàng'),
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
      default: bgColor = Colors.orange.shade50; textColor = Colors.orange; text = 'Chờ duyệt'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}