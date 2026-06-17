import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/appointment_viewmodel.dart'; 
import 'doctor_detail_screen.dart'; 

class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentViewModel>().fetchDetail(widget.appointmentId);
    });
  }

  // ==========================================
  // CÁC HÀM FORMAT DỮ LIỆU DÀNH RIÊNG CHO UI
  // ==========================================
  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} Tháng ${date.month}, ${date.year}';
  }

  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getGeneralStatus(String status) {
    if (status == 'pending' || status == 'confirmed') return 'upcoming';
    if (status == 'done') return 'completed';
    return 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<AppointmentViewModel>();
    final appointment = appVM.appointmentDetail;

    if (appVM.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor))
      );
    }
    
    if (appVM.errorMessage.isNotEmpty || appointment == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            appVM.errorMessage.isNotEmpty ? appVM.errorMessage : "Không tải được dữ liệu chi tiết.",
            style: const TextStyle(fontSize: 16, color: Colors.red),
          )
        )
      );
    }

    final generalStatus = _getGeneralStatus(appointment.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // PHẦN 1: HEADER
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
                          const Text("Chi tiết Lịch hẹn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                            backgroundImage: (appointment.doctorAvatar != null && appointment.doctorAvatar!.isNotEmpty)
                                ? NetworkImage(appointment.doctorAvatar!)
                                : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(appointment.doctorName, style: kHeaderTextStyle.copyWith(fontSize: 18)),
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

            const SizedBox(height: 20),

            // ==========================================
            // PHẦN 2: THÔNG TIN TỔNG QUAN
            // ==========================================
            _buildCardContainer(
              child: Column(
                children: [
                  _buildInfoRow("Mã đặt lịch", appointment.bookingCode, isBoldValue: true),
                  const Divider(height: 20, color: Colors.black12),
                  _buildInfoRow("Trạng thái", "", customValueWidget: _buildStatusBadge(generalStatus)),
                  const Divider(height: 20, color: Colors.black12),
                  _buildInfoRow(
                    "Thanh toán", 
                    "", 
                    customValueWidget: Text(
                      appointment.paymentStatus == 'paid' ? 'Đã thanh toán' : 'Thanh toán tại phòng khám',
                      style: TextStyle(
                        color: appointment.paymentStatus == 'paid' ? Colors.green : Colors.orange.shade800,
                        fontWeight: FontWeight.bold
                      ),
                    )
                  ),
                ],
              ),
            ),

            // ==========================================
            // PHẦN 3: THỜI GIAN & ĐỊA ĐIỂM
            // ==========================================
            _buildSectionTitle("Thời gian & Địa điểm"),
            _buildCardContainer(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time_filled, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDate(appointment.startTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("${formatTime(appointment.startTime)} - ${formatTime(appointment.endTime)}", style: const TextStyle(color: kGreyTextColor)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 25, color: Colors.black12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(appointment.type == 'offline' ? Icons.location_on : Icons.videocam, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appointment.type == 'offline' ? appointment.clinicName : "Khám trực tuyến (Video Call)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (appointment.type == 'offline') ...[
                              const SizedBox(height: 4),
                              Text(appointment.clinicAddress, style: const TextStyle(color: kGreyTextColor, height: 1.3)),
                            ]
                          ],
                        ),
                      ),
                      if (appointment.type == 'online')
                        ElevatedButton(
                          onPressed: () { /* TODO: Mở link Video Call */ },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text("Tham gia", style: TextStyle(color: Colors.white, fontSize: 12)),
                        )
                    ],
                  ),
                ],
              ),
            ),

            // ==========================================
            // PHẦN 4: THÔNG TIN BỆNH NHÂN & DỊCH VỤ
            // ==========================================
            _buildSectionTitle("Thông tin bệnh nhân"),
            _buildCardContainer(
              child: Column(
                children: [
                  _buildInfoRow("Khám cho", appointment.relation),
                  const SizedBox(height: 10),
                  _buildInfoRow("Họ và tên", appointment.patientName, isBoldValue: true),
                  const SizedBox(height: 10),
                  _buildInfoRow("Dịch vụ", appointment.serviceName),
                  const SizedBox(height: 10),
                  _buildInfoRow("Phương thức", appointment.paymentMethod == 'momo' ? 'Ví MoMo' : (appointment.paymentMethod == 'transfer' ? 'Chuyển khoản' : 'Tiền mặt')),
                  const Divider(height: 20, color: Colors.black12),
                  _buildInfoRow("Tổng tiền", formatCurrency(appointment.totalPrice), valueColor: kPrimaryColor, isBoldValue: true, valueSize: 16),
                ],
              ),
            ),

            // ==========================================
            // PHẦN 5: MÔ TẢ TRIỆU CHỨNG / GHI CHÚ
            // ==========================================
            _buildSectionTitle("Mô tả triệu chứng"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(10), 
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: Text(
                  (appointment.note != null && appointment.note!.isNotEmpty) ? appointment.note! : 'Không có ghi chú.', 
                  style: const TextStyle(color: kTextColor, height: 1.4)
                ),
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // STICKY BOTTOM BAR (Thanh hành động)
      // ==========================================
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        // ✅ Truyền context và appointment xuống để xài lệnh chuyển trang
        child: SafeArea(child: _buildBottomActions(context, appointment, generalStatus)),
      ),
    );
  }

  // ==========================================
  // CÁC WIDGET HỖ TRỢ XÂY DỰNG UI
  // ==========================================
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
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isBoldValue = false, Color? valueColor, double valueSize = 14, Widget? customValueWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: kGreyTextColor, fontSize: 14)),
        const SizedBox(width: 20),
        Expanded(
          child: customValueWidget ?? Text(
            value, 
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? kTextColor, 
              fontSize: valueSize, 
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal
            )
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String generalStatus) {
    Color bgColor; Color textColor; String text;
    
    if (generalStatus == 'upcoming') { 
      bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Sắp tới';
    } else if (generalStatus == 'completed') { 
      bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã khám';
    } else { 
      bgColor = Colors.red.shade100; textColor = Colors.red; text = 'Đã hủy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // Hàm hiển thị hộp thoại xác nhận hủy lịch và check điều kiện thời gian trực quan
  void _showCancelDialog(BuildContext context, dynamic appointment) {
    final now = DateTime.now();
    // Tính toán khoảng cách thời gian giữa thời điểm hiện tại và giờ khám
    final difference = appointment.startTime.difference(now);

    // Kiểm tra nếu thời gian còn lại dưới 2 tiếng thì chặn ngay tại giao diện
    if (difference.inHours < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy! Bạn chỉ được phép hủy lịch khám trước giờ bắt đầu ít nhất 2 tiếng.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Nếu thỏa điều kiện, mở Dialog xác nhận gợn sóng
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
              Navigator.pop(dialogContext); // Đóng nhanh dialog
              
              // Thực thi gọi hàm hủy lịch trong ViewModel tổng
              final appVM = context.read<AppointmentViewModel>();
              final result = await appVM.cancelAppointment(appointment.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['succeeded'] ? Colors.green : Colors.red,
                  ),
                );
                
                if (result['succeeded'] == true) {
                  // Đẩy lệnh tải lại chi tiết để UI cập nhật nhãn tức thì sang chữ "Đã hủy"
                  appVM.fetchDetail(appointment.id);
                }
              }
            },
            child: const Text('Đồng ý hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Hàm xây dựng thanh hành động dưới cùng với logic hiển thị nút dựa trên trạng thái chung của lịch hẹn
  Widget _buildBottomActions(BuildContext context, dynamic appointment, String generalStatus) {
    
    // Hàm đặt lại lịch
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

    if (generalStatus == 'upcoming') {
      return Row(
        children: [
          Expanded(child: _buildOutlinedButton('Đổi lịch', Colors.green, () { /* TODO: Đổi lịch */ })),
          const SizedBox(width: 10),
          Expanded(
            child: _buildOutlinedButton(
              'Hủy lịch', 
              Colors.red, 
              () => _showCancelDialog(context, appointment) // ✅ Đã gắn hàm mở Dialog
            )
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildSolidButton('Thêm Lịch', Icons.calendar_month, Colors.black87, () { /* TODO: Lịch Google */ })),
        ],
      );
    } else if (generalStatus == 'completed') {
      return Row(
        children: [
          Expanded(child: _buildOutlinedButton('Đặt lại lịch', kPrimaryColor, navigateToDoctorDetail)),
          const SizedBox(width: 15),
          Expanded(child: _buildSolidButton('Đánh giá', Icons.star_border, Colors.green, () { /* TODO: Hiện bottom sheet đánh giá */ })),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity, 
        child: _buildSolidButton('Đặt lịch mới', Icons.replay, kPrimaryColor, navigateToDoctorDetail)
      );
    }
  }

  Widget _buildOutlinedButton(String text, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color, 
        side: BorderSide(color: color), 
        padding: const EdgeInsets.symmetric(vertical: 12), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSolidButton(String text, IconData icon, Color bgColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor, 
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(vertical: 12), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
        elevation: 0
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}