import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_viewmodel.dart';
import '../../Constants/ui_constants.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  final String specialtyName;

  const AppointmentDetailScreen({super.key, required this.appointmentId, required this.specialtyName});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen>{

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminViewModel>().fetchAppointmentDetail(widget.appointmentId);
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

  String paymentMethod(String method){
    if(method == 'momo') {return 'Momo';}
    if(method == 'cash') {return 'Tiền mặt';}
    if(method == 'transfer') {return 'Chuyển khoản';}
    else{return 'VNPay';}
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final appointmentDetail = adminVM.appointmentDetail;
    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chi tiết lịch hẹn #${widget.appointmentId}', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: adminVM.isLoading
      ? Center(child: const CircularProgressIndicator(),)
      : appointmentDetail == null
        ? const Center(child: Text('Không thể lấy thông tin lịch hẹn này.', style: TextStyle(color: kGreyTextColor)))
        : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THÔNG TIN BÁC SĨ & PHÒNG KHÁM', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 12)),
                const Divider(),
                _buildDetailRow('Bác sĩ:', appointmentDetail.doctorName),
                _buildDetailRow('Chuyên khoa:', widget.specialtyName),
                const SizedBox(height: 20),
                const Text('THỜI GIAN ĐẶT HẸN', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 12)),
                const Divider(),
                _buildDetailRow('Ngày khám:', formatDate(appointmentDetail.startTime)),
                _buildDetailRow('Khung giờ:', formatTime(appointmentDetail.startTime)),
                const SizedBox(height: 20),
                const Text('TRẠNG THÁI & CHI PHÍ', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 12)),
                const Divider(),
                _buildDetailRow('Trạng thái:', formatStatus(appointmentDetail.status)),
                _buildDetailRow('Giá tiền khám:', formatCurrency(appointmentDetail.totalPrice)),
                _buildDetailRow('Phương thức thanh toán:', paymentMethod(appointmentDetail.paymentMethod)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14))),
        ],
      ),
    );
  }
}