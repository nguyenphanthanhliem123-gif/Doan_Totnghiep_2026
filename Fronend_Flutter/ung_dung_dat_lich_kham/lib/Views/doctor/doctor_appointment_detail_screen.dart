import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Services/jitsi_service.dart';
import '../../constants/ui_constants.dart';
import '../../viewmodels/doctor_appointment_detail_viewmodel.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const DoctorAppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<DoctorAppointmentDetailScreen> createState() => _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState extends State<DoctorAppointmentDetailScreen> {

  @override
  void initState() {
    super.initState();
    // Gọi API nạp dữ liệu thật ngay khi khởi tạo màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorAppointmentDetailViewModel>().fetchAppointmentDetail(widget.appointmentId);
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "Chưa rõ";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')} Tháng ${date.month}, ${date.year}';
    } catch (e) {
      return "Chưa rõ";
    }
  }

  String formatTime(String? dateStr) {
    if (dateStr == null) return "Chưa rõ";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return "Chưa rõ";
    }
  }

    String formatCurrency(dynamic amount) {
      if (amount == null) return "0 vnđ";
      try {
        String result = amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        return '$result vnđ';
      } catch (e) {
        return "$amount vnđ";
      }
    }

  void _handleJoinMeeting(String bookingCode) async {
    try {
      await JitsiService.joinOnlineConsultation(
        bookingCode: bookingCode,
        patientName: "Bác sĩ phụ trách", 
        patientEmail: "doctor@healthcare.com",
      );
    } catch (e) {
      print("LỖI KHI GỌI JITSI: $e"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorAppointmentDetailViewModel>();
    final appointment = vm.appointmentDetail;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : appointment == null
              ? const Center(child: Text("Không thể tải thông tin ca khám này."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // PHẦN 1: HEADER - THÔNG TIN BỆNH NHÂN
                      // ==========================================
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const Text("Chi tiết Ca Khám", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 48), 
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (appointment['patientAvatar'] != null && appointment['patientAvatar'].toString().startsWith('http'))
                                          ? NetworkImage(appointment['patientAvatar'])
                                          : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(appointment['patientName'] ?? 'Bệnh nhân', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 5),
                                          Text("${appointment['patientAge'] ?? 0} tuổi • ${appointment['patientGender'] ?? 'Chưa rõ'}", style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==========================================
                      // 🌟 MỚI: NGƯỜI LIÊN HỆ (Chỉ hiện khi khám cho người thân)
                      // ==========================================
                      if (appointment['isRelative'] == 1) ...[
                        _buildSectionTitle("Người liên hệ (Chủ tài khoản)"),
                        _buildCardContainer(
                          child: Column(
                            children: [
                              _buildInfoRow("Họ và tên", appointment['contactName'] ?? 'Chưa rõ', isBoldValue: true),
                              const Divider(height: 20, color: Colors.black12),
                              _buildInfoRow("Điện thoại", appointment['contactPhone'] ?? 'Chưa cập nhật', valueColor: kPrimaryColor, isBoldValue: true),
                              const Divider(height: 20, color: Colors.black12),
                              _buildInfoRow("Quan hệ", appointment['relationship'] ?? 'Chưa rõ'),
                            ],
                          ),
                        ),
                      ],

                      // ==========================================
                      // PHẦN 2: THÔNG TIN CA KHÁM & DỊCH VỤ
                      // ==========================================
                      _buildSectionTitle("Thông tin ca khám"),
                      _buildCardContainer(
                        child: Column(
                          children: [
                            _buildInfoRow("Mã đặt lịch", appointment['bookingCode'] ?? 'Chưa rõ', isBoldValue: true),
                            const Divider(height: 20, color: Colors.black12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.access_time_filled, color: kPrimaryColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(formatDate(appointment['startTime']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text("${formatTime(appointment['startTime'])} - ${formatTime(appointment['endTime'])}", style: const TextStyle(color: kGreyTextColor)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Divider(height: 25, color: Colors.black12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(appointment['type'] == 'offline' ? Icons.meeting_room : Icons.videocam, color: Colors.redAccent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    appointment['type'] == 'offline' ? "Khám trực tiếp tại phòng khám" : "Khám trực tuyến (Video Call)", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 25, color: Colors.black12),
                            _buildInfoRow("Dịch vụ khám", appointment['selectedServices'] ?? 'Đang cập nhật', isBoldValue: true, valueColor: kPrimaryColor),
                            
                            // 🌟 MỚI: THÔNG TIN THANH TOÁN
                            const Divider(height: 25, color: Colors.black12),
                            _buildInfoRow("Tổng tiền", formatCurrency(appointment['totalAmount']), isBoldValue: true, valueColor: Colors.redAccent),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Thanh toán", 
                              appointment['paymentStatus'] == 'paid' 
                                  ? "Đã thanh toán (${appointment['paymentMethod'] == 'vnpay' ? 'VNPay' : 'Tiền mặt'})" 
                                  : "Chờ thu tiền (${appointment['paymentMethod'] == 'vnpay' ? 'VNPay' : 'Tại phòng khám'})",
                              valueColor: appointment['paymentStatus'] == 'paid' ? Colors.green : Colors.orange,
                              isBoldValue: true
                            ),
                          ],
                        ),
                      ),

                      // ==========================================
                      // PHẦN 3: TRIỆU CHỨNG LÂM SÀNG
                      // ==========================================
                      _buildSectionTitle("Triệu chứng bệnh nhân nhập"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50, 
                            borderRadius: BorderRadius.circular(10), 
                            border: Border.all(color: Colors.red.shade200)
                          ),
                          child: Text(
                            (appointment['symptoms'] == null || appointment['symptoms'].toString().trim().isEmpty) 
                                ? 'Không có ghi chú triệu chứng.' 
                                : appointment['symptoms'], 
                            style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 15)
                          ),
                        ),
                      ),

                      // ==========================================
                      // 🌟 MỚI: PHẦN 4 - HỒ SƠ Y TẾ (TIỀN SỬ BỆNH) KHÔI PHỤC
                      // ==========================================
                      _buildSectionTitle("Hồ sơ y tế / Tiền sử bệnh"),
                      _buildCardContainer(
                        child: Column(
                          children: [
                            _buildInfoRow("Nhóm máu", appointment['bloodType'] ?? 'Chưa cập nhật', isBoldValue: true, valueColor: Colors.red),
                            const Divider(height: 20, color: Colors.black12),
                            _buildInfoRow("Dị ứng", appointment['allergies'] ?? 'Không ghi nhận', isBoldValue: appointment['allergies'] != null),
                            const Divider(height: 20, color: Colors.black12),
                            _buildInfoRow("Bệnh nền", appointment['backgroundDiseases'] ?? 'Không ghi nhận', isBoldValue: appointment['backgroundDiseases'] != null),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomSheet: vm.isLoading || appointment == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white, 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
              ),
              child: SafeArea(child: _buildDoctorBottomActions(context, appointment)),
            ),
    );
  }

  Widget _buildDoctorBottomActions(BuildContext context, Map<String, dynamic> appointment) {
    String status = appointment['status'] ?? 'pending';

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(child: _buildOutlinedButton('Từ chối', Colors.red, () {
            // Thao tác từ chối gọi API thông qua màn hình danh sách chung hoặc xử lý tại chỗ
          })),
          const SizedBox(width: 15),
          Expanded(child: _buildSolidButton('Xác nhận', Icons.check_circle, Colors.green, () {
            // Thao tác xác nhận gọi API
          })),
        ],
      );
    } 
    
    if (status == 'confirmed') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (appointment['type'] == 'online') ...[
            SizedBox(
              width: double.infinity,
              child: _buildSolidButton('Vào phòng khám Online', Icons.videocam, Colors.blueAccent, () {
                _handleJoinMeeting(appointment['bookingCode'] ?? '');
              })
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: _buildSolidButton('Khám xong & Kê đơn', Icons.edit_document, kPrimaryColor, () {
              print("Chuyển sang trang kê đơn");
            })
          ),
        ],
      );
    }

    if (status == 'done') {
      return SizedBox(
        width: double.infinity,
        child: _buildOutlinedButton('Xem lại đơn thuốc', kPrimaryColor, () {})
      );
    }

    return const SizedBox.shrink(); 
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
      child: Text(title, style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: child,
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isBoldValue = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: kGreyTextColor, fontSize: 14)),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor ?? kTextColor, fontSize: 14, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal)
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedButton(String text, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSolidButton(String text, IconData icon, Color bgColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: bgColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}