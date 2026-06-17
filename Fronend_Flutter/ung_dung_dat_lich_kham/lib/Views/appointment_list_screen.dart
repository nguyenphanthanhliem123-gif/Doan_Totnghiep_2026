import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../models/appointment_model.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentViewModel>().loadMyAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<AppointmentViewModel>();

    return DefaultTabController(
      length: 3, // 3 Tabs
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Lịch hẹn của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Đã khám'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: appVM.isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : TabBarView(
                children: [
                  _buildList(appVM.upcomingList, 'upcoming'),
                  _buildList(appVM.completedList, 'completed'),
                  _buildList(appVM.cancelledList, 'cancelled'),
                ],
              ),
      ),
    );
  }

  // --- HÀM BUILD DANH SÁCH ---
  Widget _buildList(List<AppointmentModel> list, String tabType) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Chưa có lịch hẹn nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () => context.read<AppointmentViewModel>().loadMyAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(list[index], tabType);
        },
      ),
    );
  }

  // --- HÀM BUILD TỪNG THẺ (CARD) ---
  Widget _buildAppointmentCard(AppointmentModel appointment, String tabType) {
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
      // Bọc Material và InkWell để toàn bộ thẻ có thể bấm được kèm hiệu ứng gợn sóng (ripple)
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // TODO: Chuyển sang trang Chi tiết lịch hẹn
            print("Mở chi tiết lịch hẹn mã: ${appointment.bookingCode}");
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER (Bác sĩ & Trạng thái)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: appointment.doctorAvatar != null 
                          ? NetworkImage(appointment.doctorAvatar!) 
                          : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Mã: ${appointment.bookingCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(tabType), // Gộp nhãn dựa trên Tab hiện tại
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.black12),
                ),

                // 2. BODY (Thời gian & Hình thức)
                Text(
                  'Thời gian: ${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')} • ${appointment.startTime.day.toString().padLeft(2, '0')}/${appointment.startTime.month.toString().padLeft(2, '0')}/${appointment.startTime.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hình thức: ${appointment.type == "online" ? "Khám trực tuyến (Video Call)" : "Khám trực tiếp"}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),

                const SizedBox(height: 16),

                // 3. FOOTER (Nút hành động)
                _buildFooterButtons(appointment, tabType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC GẮN NHÃN TRẠNG THÁI ---
  Widget _buildStatusBadge(String tabType) {
    Color bgColor;
    Color textColor;
    String text;

    if (tabType == 'upcoming') {
      bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Sắp tới';
    } else if (tabType == 'completed') {
      bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã khám';
    } else {
      bgColor = Colors.red.shade100; textColor = Colors.grey.shade700; text = 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // --- LOGIC CHỌN NÚT THEO TAB ---
  Widget _buildFooterButtons(AppointmentModel appointment, String tabType) {
    if (tabType == 'upcoming') {
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.refresh, text: 'Đổi lịch hẹn', 
              color: Colors.green, bgColor: Colors.green.shade50, onTap: () { /* TODO: Đổi lịch */ }
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.cancel_outlined, text: 'Hủy lịch hẹn', 
              color: Colors.red, bgColor: Colors.red.shade50, onTap: () { /* TODO: Hủy */ }
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.calendar_month, text: 'Thêm vào\nGoogle Calendar', 
              color: Colors.grey.shade800, bgColor: Colors.grey.shade200, onTap: () { /* TODO: Lịch Google */ }
            ),
          ),
        ],
      );
    } else if (tabType == 'completed') {
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.replay, text: 'Đặt lại lịch', 
              color: kPrimaryColor, bgColor: Colors.cyan.shade50, onTap: () { /* TODO: Đặt lại lịch */ }
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.star_border, text: 'Đánh giá', 
              color: Colors.white, bgColor: Colors.green, onTap: () { /* TODO: BottomSheet Đánh giá */ }
            ),
          ),
        ],
      );
    } else {
      // Tab Đã hủy
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.replay, text: 'Đặt lại lịch', 
              color: Colors.white, bgColor: kPrimaryColor, onTap: () { /* TODO: Quay lại đặt lịch */ }
            ),
          ),
        ],
      );
    }
  }

  // Widget Button phụ trợ dùng chung cho dễ tùy biến màu sắc và tỷ lệ dàn trang
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
            Text(
              text, 
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}