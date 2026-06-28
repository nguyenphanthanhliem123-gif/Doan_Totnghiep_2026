import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_viewmodel.dart';
import '../../Constants/ui_constants.dart';
import 'appointment_detail_screen.dart'; // Import màn hình chi tiết cuộc hẹn

class PatientAppointmentHistoryScreen extends StatefulWidget {
  final dynamic patient;

  const PatientAppointmentHistoryScreen({super.key, required this.patient});

  @override
  State<PatientAppointmentHistoryScreen> createState() => _PatientAppointmentHistoryScreenState();
}

class _PatientAppointmentHistoryScreenState extends State<PatientAppointmentHistoryScreen>{

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminViewModel>().loadAppointmentsByUserId(widget.patient.id);
    });
    super.initState();
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} Tháng ${date.month}, ${date.year}';
  }

  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  String formatStatus(String status){
    if(status == 'pending') {return 'Đang chờ';}
    if(status == 'confirmed') {return 'Đã xác nhận';}
    if(status == 'done') {return 'Đã khám';}
    if(status == 'cancelled') {return 'Đã hủy';}
    else {return 'Vắng mặt';}
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final listAppointment = adminVM.allAppointments;

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Lịch sử đặt lịch', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.patient.fullName ?? '', style: const TextStyle(color: kGreyTextColor, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body:
       SafeArea(
        child:  adminVM.isLoading
        ? Center(child: CircularProgressIndicator(),)
        : listAppointment.isEmpty
            ? const Center(child: Text('Bệnh nhân chưa có lịch sử đặt hẹn nào', style: TextStyle(color: kGreyTextColor)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: listAppointment.length,
                itemBuilder: (context, index) {
                  final item = listAppointment[index];
                  Color stateColor = Colors.green;
                  if (item.status == 'pending') stateColor = Colors.orange;
                  if (item.status == 'cancelled') stateColor = Colors.red;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                      onTap: () {
                        // 🌟 NHẤN VÀO 1 LỊCH SỬ SẼ RA TRANG CHI TIẾT LỊCH HẸN ĐÓ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailScreen(appointmentId: item.id, specialtyName: item.specialtyName ?? '',),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('Chuyên khoa: ${item.specialtyName}', style: const TextStyle(color: kGreyTextColor, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: kGreyTextColor),
                                      const SizedBox(width: 4),
                                      Text(formatDate(item.startTime), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.access_time, size: 14, color: kGreyTextColor),
                                      const SizedBox(width: 4),
                                      Text(formatTime(item.startTime), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatCurrency(double.parse(item.totalPrice)), style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(color: stateColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    formatStatus(item.status),
                                    style: TextStyle(color: stateColor, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}