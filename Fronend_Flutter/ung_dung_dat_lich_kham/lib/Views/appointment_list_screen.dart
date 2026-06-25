import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/review_screen.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đã sửa thành Constants
import '../viewmodels/appointment_viewmodel.dart';
import '../models/appointment_model.dart';
import 'appointment_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'reschedule_bottom_sheet.dart';
import '../utils/add_to_google_calendar_utils.dart';

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
      length: 3,
      child: Scaffold(
        backgroundColor: kLightCyanBg2, // 🌟 Chuẩn hóa nền app sáng mịn
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Lịch hẹn của tôi', style: kHeaderTextStyle), // 🌟 Chuẩn hóa Text style
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

  Widget _buildList(List<AppointmentModel> list, String tabType) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Chưa có lịch hẹn nào.', style: TextStyle(color: kGreyTextColor, fontSize: 16)),
      );
    }
    
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: () => context.read<AppointmentViewModel>().loadMyAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding), // 🌟 Lề 20
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(list[index], tabType);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, String tabType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // 🌟 Bo 20
        border: Border.all(color: kBorderCyan),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointmentId: appointment.id,
                ),
              ),
            );
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
                      backgroundColor: kLightCyanBg1,
                      backgroundImage: appointment.doctorAvatar != null 
                          ? NetworkImage(appointment.doctorAvatar!) 
                          : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                          const SizedBox(height: 4),
                          Text('Mã: ${appointment.bookingCode}', style: const TextStyle(fontSize: 12, color: kGreyTextColor)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(tabType), 
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: kBorderCyan),
                ),

                Text(
                  'Thời gian: ${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')} • ${appointment.startTime.day.toString().padLeft(2, '0')}/${appointment.startTime.month.toString().padLeft(2, '0')}/${appointment.startTime.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hình thức: ${appointment.type == "online" ? "Khám trực tuyến (Video Call)" : "Khám trực tiếp"}',
                  style: const TextStyle(fontSize: 14, color: kTextColor),
                ),

                const SizedBox(height: 16),

                _buildFooterButtons(context, appointment, tabType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String tabType) {
    Color bgColor; Color textColor; String text;

    if (tabType == 'upcoming') {
      bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Sắp tới';
    } else if (tabType == 'completed') {
      bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã khám';
    } else {
      bgColor = Colors.red.shade100; textColor = Colors.red; text = 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _showCancelDialog(BuildContext context, AppointmentModel appointment) {
    final now = DateTime.now();
    final difference = appointment.startTime.difference(now);

    if (difference.inHours < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy! Bạn chỉ được phép hủy lịch khám trước giờ bắt đầu ít nhất 2 tiếng.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận hủy lịch', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn khám này không? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 
              
              final appVM = context.read<AppointmentViewModel>();
              final result = await appVM.cancelAppointment(appointment.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['succeeded'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Đồng ý hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context, AppointmentModel appointment, String tabType) {
    void navigateToDoctorDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDetailScreen(
            doctorId: appointment.doctorId,
          ),
        ),
      );
    }

    if (tabType == 'upcoming') {
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.refresh, text: 'Đổi lịch hẹn', 
              color: Colors.green, bgColor: Colors.green.shade50, 
              onTap: () {
                final now = DateTime.now();
                final difference = appointment.startTime.difference(now);
                if (difference.inHours < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể đổi! Bạn chỉ được dời lịch trước giờ bắt đầu ít nhất 2 tiếng.'), 
                      backgroundColor: Colors.redAccent
                    )
                  );
                  return;
                }
                
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, 
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => RescheduleBottomSheet(
                    appointmentId: appointment.id,
                    doctorId: appointment.doctorId,
                  ),
                );
              }
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.cancel_outlined, text: 'Hủy lịch hẹn', 
              color: Colors.red, bgColor: Colors.red.shade50, 
              onTap: () => _showCancelDialog(context, appointment),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.calendar_month, 
              text: 'Thêm vào\nGoogle Calendar', 
              color: Colors.grey.shade800, 
              bgColor: Colors.grey.shade200, 
              onTap: () => CalendarUtils.addToCalendar(context, appointment)
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
              color: kPrimaryColor, bgColor: kLightCyanBg1, 
              onTap: navigateToDoctorDetail,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionBtn(
              icon: Icons.star_border, text: 'Đánh giá', 
              color: Colors.white, bgColor: Colors.green, onTap: () { Navigator.of( context ).push(
                MaterialPageRoute(builder: (context) => ReviewScreen(appointmentId: appointment.id))
              ); }
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              icon: Icons.replay, text: 'Đặt lại lịch', 
              color: Colors.white, bgColor: kPrimaryColor, 
              onTap: navigateToDoctorDetail,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionBtn({required IconData icon, required String text, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall), // 🌟 Bo 12
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
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