import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/doctor_appointment_list_viewmodel.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  State<DoctorAppointmentScreen> createState() => _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorAppointmentListViewModel>().loadAllAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorAppointmentListViewModel>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Quản lý Lịch hẹn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Đã khám'),
              Tab(text: 'Đã hủy'),
              Tab(text: 'Vắng mặt'),
            ],
          ),
        ),
        body: vm.isLoading && vm.pendingList.isEmpty && vm.confirmedList.isEmpty
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : TabBarView(
                children: [
                  _buildList(context, vm.pendingList, 'pending'),
                  _buildList(context, vm.confirmedList, 'confirmed'),
                  _buildList(context, vm.doneList, 'done'),
                  _buildList(context, vm.cancelledList, 'cancelled'),
                  _buildList(context, vm.absentList, 'absent'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> list, String status) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Không có lịch hẹn nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () => context.read<DoctorAppointmentListViewModel>().loadAllAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(context, list[index], status);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, dynamic appointment, String status) {
    // Ép kiểu thời gian UTC từ DB sang Local Việt Nam để hiển thị chuẩn xác
    final localStart = DateTime.parse(appointment['Thoi_gian_Bdau']).toLocal();
    final localEnd = DateTime.parse(appointment['Thoi_gian_Kthuc']).toLocal();
    
    final timeStr = "${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')} - ${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}";
    final dateStr = "${localStart.day.toString().padLeft(2, '0')}/${localStart.month.toString().padLeft(2, '0')}/${localStart.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Điều hướng sang xem chi tiết (sẽ phát triển sau)
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      backgroundImage: appointment['Anh_benh_nhan'] != null
                          ? NetworkImage(appointment['Anh_benh_nhan'])
                          : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment['Ten_benh_nhan'] ?? 'Bệnh nhân', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Mã đặt lịch: ${appointment['Ma_booking']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status), 
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.black12),
                ),

                Text(
                  'Thời gian: $timeStr • $dateStr',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hình thức: ${appointment['Hinh_thuc'] == "online" ? "Khám trực tuyến (Video Call)" : "Khám trực tiếp tại phòng khám"}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),

                const SizedBox(height: 16),

                _buildFooterButtons(context, appointment['Ma_lich_hen'], status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor; Color textColor; String text;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.shade50; textColor = Colors.orange; text = 'Chờ duyệt'; break;
      case 'confirmed':
        bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Đã duyệt'; break;
      case 'done':
        bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã khám'; break;
      case 'cancelled':
        bgColor = Colors.red.shade50; textColor = Colors.red; text = 'Đã hủy'; break;
      case 'absent':
      default:
        bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; text = 'Vắng mặt'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFooterButtons(BuildContext context, int appointmentId, String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.cancel_outlined, text: 'Từ chối', 
              color: Colors.red, bgColor: Colors.red.shade50, 
              onTap: () => _handleAction(context, appointmentId, 'reject'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.check_circle_outline, text: 'Xác nhận', 
              color: Colors.white, bgColor: kPrimaryColor, 
              onTap: () => _handleAction(context, appointmentId, 'confirm'),
            ),
          ),
        ],
      );
    } else if (status == 'confirmed') {
      return Row(
        children: [
          Expanded(child: _buildActionBtn(icon: Icons.person_off_outlined, text: 'Báo vắng', color: Colors.orange, bgColor: Colors.orange.shade50, onTap: () {})),
          const SizedBox(width: 8),
          Expanded(child: _buildActionBtn(icon: Icons.task_alt, text: 'Hoàn thành', color: Colors.white, bgColor: Colors.green, onTap: () {})),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildActionBtn(icon: Icons.visibility, text: 'Xem chi tiết ca khám', color: kPrimaryColor, bgColor: Colors.cyan.shade50, onTap: () {})),
        ],
      );
    }
  }

  Widget _buildActionBtn({required IconData icon, required String text, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, int appointmentId, String action) async {
    final result = await context.read<DoctorAppointmentListViewModel>().updateStatus(appointmentId, action);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }
}