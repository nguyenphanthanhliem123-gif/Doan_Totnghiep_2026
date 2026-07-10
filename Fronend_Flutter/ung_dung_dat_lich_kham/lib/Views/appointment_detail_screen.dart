import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Services/jitsi_service.dart';
import 'package:ung_dung_dat_lich_kham/Views/report_bottom_sheet.dart';
import 'package:ung_dung_dat_lich_kham/Views/review_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đã sửa thành Constants
import '../viewmodels/appointment_viewmodel.dart'; 
import 'doctor_detail_screen.dart';
import 'reschedule_bottom_sheet.dart'; 
import '../utils/add_to_google_calendar_utils.dart';

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

  bool _canJoinMeeting(DateTime startTime) {
    final now = DateTime.now();
    final startTimeBuffer = startTime.subtract(const Duration(minutes: 15));
    final endTimeBuffer = startTime.add(const Duration(hours: 1)); 
    return now.isAfter(startTimeBuffer) && now.isBefore(endTimeBuffer);
  }

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

  void _handleJoinMeeting(String bookingCode, String patientName) async {
    try {
      print("Đang bắt đầu gọi Jitsi cho: $bookingCode");
      await JitsiService.joinOnlineConsultation(
        bookingCode: bookingCode,
        patientName: patientName, 
        patientEmail: "patient@email.com",
      );
      print("Đã gọi hàm Jitsi thành công");
    } catch (e) {
      print("LỖI KHI GỌI JITSI: $e");
    }
  }

  void _showViewPrescriptionBottomSheet(BuildContext context) {
    context.read<AppointmentViewModel>().fetchPrescription(widget.appointmentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Consumer<AppointmentViewModel>(
              builder: (context, vm, child) {
                final data = vm.prescriptionData;

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 15),
                      height: 5, width: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                    const Text("Chi tiết Đơn Thuốc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const Divider(height: 20, color: kBorderCyan),
                    
                    Expanded(
                      child: vm.isPrescriptionLoading
                          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                          : data == null
                              ? const Center(child: Text("Không tìm thấy đơn thuốc cho ca khám này.", style: TextStyle(color: kGreyTextColor)))
                              : SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Kết luận bệnh lý", style: TextStyle(color: kGreyTextColor, fontSize: 13)),
                                      const SizedBox(height: 5),
                                      Text(data['Chuan_doan_benh'] ?? 'Chưa cập nhật', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      const SizedBox(height: 15),

                                      if (data['Ngay_tai_kham'] != null) ...[
                                        const Text("Ngày tái khám", style: TextStyle(color: kGreyTextColor, fontSize: 13)),
                                        const SizedBox(height: 5),
                                        Text(
                                          () {
                                            try {
                                              final date = DateTime.parse(data['Ngay_tai_kham']);
                                              return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                            } catch (e) {
                                              return data['Ngay_tai_kham'].toString();
                                            }
                                          }(), 
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryColor)
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      const Divider(color: kBorderCyan),
                                      const SizedBox(height: 10),
                                      const Text("Danh sách thuốc", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor)),
                                      const SizedBox(height: 10),

                                      if (data['Danh_sach_thuoc'] != null && (data['Danh_sach_thuoc'] as List).isNotEmpty)
                                        ...List.generate((data['Danh_sach_thuoc'] as List).length, (index) {
                                          final thuoc = data['Danh_sach_thuoc'][index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: kLightCyanBg2,
                                              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                              border: Border.all(color: kBorderCyan)
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("${index + 1}.", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: Text(thuoc['Ten_thuoc'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor))),
                                                    Text("SL: ${thuoc['So_luong']}", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 25),
                                                  child: Text("Cách dùng: ${thuoc['Lieu_dung'] ?? ''}", style: const TextStyle(color: kGreyTextColor, fontSize: 13)),
                                                )
                                              ],
                                            ),
                                          );
                                        })
                                      else
                                        const Text("Không có thuốc nào được kê.", style: TextStyle(color: kGreyTextColor, fontStyle: FontStyle.italic)),
                                        
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<AppointmentViewModel>();
    final appointment = appVM.appointmentDetail;

    if (appVM.isLoading) {
      return const Scaffold(
        backgroundColor: kLightCyanBg2, // 🌟 Nền chuẩn
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
      backgroundColor: kLightCyanBg2, // 🌟 Chuẩn nền
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
                          const Text("Chi tiết Lịch hẹn", style: kHeaderTextStyle), // 🌟 Chuẩn Text
                          const SizedBox(width: 48), 
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding), // 🌟 Lề 20
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            // 🌟 FIX LỖI 2: Giữ nguyên logic NetworkImage tránh crash app
                            backgroundImage: (appointment.doctorAvatar != null && 
                                             appointment.doctorAvatar!.isNotEmpty && 
                                             appointment.doctorAvatar!.startsWith('http'))
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
                  const Divider(height: 20, color: kBorderCyan),
                  _buildInfoRow("Trạng thái", "", customValueWidget: _buildStatusBadge(generalStatus)),
                  const Divider(height: 20, color: kBorderCyan),
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
                            Text(formatDate(appointment.startTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor)),
                            const SizedBox(height: 4),
                            Text("${formatTime(appointment.startTime)} - ${formatTime(appointment.endTime)}", style: const TextStyle(color: kGreyTextColor)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 25, color: kBorderCyan),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(appointment.type == 'offline' ? Icons.location_on : Icons.videocam, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appointment.type == 'offline' ? appointment.clinicName : "Khám trực tuyến (Video Call)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor)),
                            if (appointment.type == 'offline') ...[
                              const SizedBox(height: 4),
                              Text(appointment.clinicAddress, style: const TextStyle(color: kGreyTextColor, height: 1.3)),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 🌟 FIX LỖI 1: Nút Jitsi Full Width (Giữ nguyên logic của bạn)
                  if (appointment.type == 'online' && appointment.status != 'done' && appointment.status != 'cancelled') ...[
                    const SizedBox(height: 15),
                    Consumer<AppointmentViewModel>(
                      builder: (context, vm, child) {
                        bool canJoin = _canJoinMeeting(appointment.startTime);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: canJoin 
                                ? () { 
                                    print("Đã nhấn nút tham gia!");
                                    _handleJoinMeeting(appointment.bookingCode, appointment.patientName); 
                                  }
                                : null, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canJoin ? Colors.blueAccent : Colors.grey[300],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Bo 12
                              elevation: canJoin ? 2 : 0,
                            ),
                            icon: Icon(Icons.videocam, color: canJoin ? Colors.white : Colors.grey),
                            label: Text(
                              canJoin ? "Tham gia phòng khám" : "Chưa đến giờ khám",
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold,
                                color: canJoin ? Colors.white : Colors.grey.shade600
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ]
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
                  const Divider(height: 20, color: kBorderCyan),
                  _buildInfoRow("Tổng tiền", formatCurrency(appointment.totalPrice), valueColor: kPrimaryColor, isBoldValue: true, valueSize: 16),
                ],
              ),
            ),

            // ==========================================
            // PHẦN 5: MÔ TẢ TRIỆU CHỨNG / GHI CHÚ
            // ==========================================
            _buildSectionTitle("Mô tả triệu chứng"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall), // 🌟 Bo 12
                  border: Border.all(color: kBorderCyan)
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
      // STICKY BOTTOM BAR
      // ==========================================
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: SafeArea(child: _buildBottomActions(context, appointment, generalStatus)),
      ),
    );
  }

  // ==========================================
  // CÁC WIDGET HỖ TRỢ XÂY DỰNG UI
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: kDefaultPadding, top: 25, bottom: 10),
      child: Text(title, style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // 🌟 Bo 20
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
          child: customValueWidget != null
              ? Align(alignment: Alignment.centerRight, child: customValueWidget) 
              : Text(
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

  void _showCancelDialog(BuildContext context, dynamic appointment) {
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
                
                if (result['succeeded'] == true) {
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

  Widget _buildBottomActions(BuildContext context, dynamic appointment, String generalStatus) {
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
          Expanded(
            child: _buildOutlinedButton(
              'Đổi lịch', 
              Colors.green, 
              () {
                final now = DateTime.now();
                final difference = appointment.startTime.difference(now);
                if (difference.inHours < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể đổi! Bạn chỉ được dời lịch trước giờ bắt đầu ít nhất 2 tiếng.'), backgroundColor: Colors.redAccent));
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
            )
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildOutlinedButton(
              'Hủy lịch', 
              Colors.red, 
              () => _showCancelDialog(context, appointment) 
            )
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSolidButton(
              'Thêm Lịch', 
              Icons.calendar_month, 
              Colors.black87, 
              () => CalendarUtils.addToCalendar(context, appointment)
            )
          ),
        ],
      );
    } else if (generalStatus == 'completed') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _buildSolidButton('Xem lại đơn thuốc', Icons.receipt_long, kPrimaryColor, () {
              _showViewPrescriptionBottomSheet(context);
            })
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildOutlinedButton('Đặt lại lịch', kPrimaryColor, navigateToDoctorDetail)),
              const SizedBox(width: 15),
              Expanded(child: _buildSolidButton('Đánh giá', Icons.star_border, Colors.green, () { 
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ReviewScreen(appointmentId: appointment.id))
                ); 
              })),
            ],
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)) // Bo 12
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Bo 12
        elevation: 0
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}