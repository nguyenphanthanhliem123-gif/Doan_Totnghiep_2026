import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Services/jitsi_service.dart';
import 'package:ung_dung_dat_lich_kham/Views/report_bottom_sheet.dart';
import '../../Constants/ui_constants.dart'; // 🌟 Chuẩn hóa đường dẫn
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

  // 🌟 HÀM MỞ BOTTOM SHEET XEM LỊCH SỬ BỆNH ÁN
  void _showMedicalHistory(BuildContext context) {
    context.read<DoctorAppointmentDetailViewModel>().fetchMedicalHistory(widget.appointmentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))), // 🌟 Bo 20 chuẩn
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6, 
          minChildSize: 0.4,
          maxChildSize: 0.9, 
          builder: (context, scrollController) {
            return Consumer<DoctorAppointmentDetailViewModel>(
              builder: (context, vm, child) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 15),
                      height: 5, width: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                    const Text("Lịch sử khám bệnh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const Divider(height: 20, color: kBorderCyan),
                    
                    Expanded(
                      child: vm.isHistoryLoading
                          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                          : vm.medicalHistory.isEmpty
                              ? const Center(child: Text("Bệnh nhân chưa có lịch sử khám bệnh nào.", style: TextStyle(color: kGreyTextColor)))
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 10), // 🌟 Lề 20
                                  itemCount: vm.medicalHistory.length,
                                  itemBuilder: (context, index) {
                                    final item = vm.medicalHistory[index];
                                    return Card(
                                      elevation: 0, // Bỏ bóng đổ, dùng viền chuẩn
                                      margin: const EdgeInsets.only(bottom: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall), side: const BorderSide(color: kBorderCyan)), // 🌟 Bo 12
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_month, size: 16, color: kPrimaryColor),
                                                const SizedBox(width: 5),
                                                Text(formatDate(item['Ngay_kham']), style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 15)),
                                              ],
                                            ),
                                            const Divider(height: 15, color: kBorderCyan),
                                            _buildHistoryRow("Bác sĩ:", item['Ten_bac_si'] ?? 'Chưa rõ'),
                                            const SizedBox(height: 5),
                                            _buildHistoryRow("Triệu chứng:", item['Trieu_chung'] ?? 'Không ghi nhận'),
                                            const SizedBox(height: 5),
                                            _buildHistoryRow("Chẩn đoán:", item['Chuan_doan_benh'] ?? 'Chưa có chẩn đoán', valueColor: Colors.redAccent),
                                            const SizedBox(height: 5),
                                            _buildHistoryRow("Đơn thuốc:", item['Danh_sach_thuoc'] ?? 'Không kê thuốc'),
                                            if (item['Loi_dan'] != null && item['Loi_dan'].toString().trim().isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              _buildHistoryRow("Lời dặn:", item['Loi_dan']),
                                            ]
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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

  // 🌟 Hàm hiển thị Bottomsheet kê đơn thuốc
  void _showPrescriptionBottomSheet(BuildContext context) {
    final TextEditingController chanDoanCtrl = TextEditingController();
    DateTime? selectedDate;
    List<Map<String, TextEditingController>> medicines = [];

    void addMedicine() {
      medicines.add({
        "tenThuoc": TextEditingController(),
        "soLuong": TextEditingController(),
        "lieuDung": TextEditingController(),
      });
    }

    addMedicine();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))), // 🌟 Bo 20
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                left: kDefaultPadding, right: kDefaultPadding, top: 15
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 15),
                    const Text("Kết luận & Kê đơn thuốc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const SizedBox(height: 20),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Chẩn đoán bệnh lý *", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: chanDoanCtrl,
                              maxLines: 2,
                              style: const TextStyle(color: kTextColor),
                              decoration: InputDecoration(
                                hintText: "Nhập kết luận khám...",
                                hintStyle: const TextStyle(color: kGreyTextColor),
                                fillColor: kLightCyanBg1, // 🌟 Nền chuẩn
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall), borderSide: BorderSide.none), // 🌟 Bo 12
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 15),

                            const Text("Ngày tái khám (Tùy chọn)", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(primary: kPrimaryColor),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null && picked != selectedDate) {
                                  setModalState(() { selectedDate = picked; });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Nền chuẩn
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(selectedDate != null ? "${selectedDate!.day.toString().padLeft(2,'0')}/${selectedDate!.month.toString().padLeft(2,'0')}/${selectedDate!.year}" : "Chọn ngày tái khám", style: TextStyle(color: selectedDate != null ? kTextColor : kGreyTextColor)),
                                    const Icon(Icons.calendar_today, size: 18, color: kPrimaryColor),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: kSpacingLarge),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Đơn thuốc", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor)),
                                TextButton.icon(
                                  onPressed: () => setModalState(() => addMedicine()),
                                  icon: const Icon(Icons.add_circle, size: 18, color: kPrimaryColor),
                                  label: const Text("Thêm thuốc", style: TextStyle(color: kPrimaryColor)),
                                )
                              ],
                            ),
                            
                            ...List.generate(medicines.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: kLightCyanBg2, border: Border.all(color: kBorderCyan), borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Bo 12
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: medicines[index]["tenThuoc"],
                                            style: const TextStyle(color: kTextColor),
                                            decoration: const InputDecoration(labelText: "Tên thuốc *", labelStyle: TextStyle(color: kGreyTextColor), isDense: true),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller: medicines[index]["soLuong"],
                                            style: const TextStyle(color: kTextColor),
                                            decoration: const InputDecoration(labelText: "Số lượng *", labelStyle: TextStyle(color: kGreyTextColor), isDense: true),
                                          ),
                                        ),
                                        if (medicines.length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => setModalState(() => medicines.removeAt(index)),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: medicines[index]["lieuDung"],
                                      style: const TextStyle(color: kTextColor),
                                      decoration: const InputDecoration(labelText: "Cách dùng / Liều lượng *", labelStyle: TextStyle(color: kGreyTextColor), isDense: true),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall))), // 🌟 Bo 12
                        onPressed: () async {
                          if (chanDoanCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập chẩn đoán bệnh!")));
                            return;
                          }

                          List<Map<String, dynamic>> danhSachThuocData = [];
                          for (var med in medicines) {
                            if (med["tenThuoc"]!.text.trim().isNotEmpty) {
                              danhSachThuocData.add({
                                "tenThuoc": med["tenThuoc"]!.text.trim(),
                                "soLuong": med["soLuong"]!.text.trim(),
                                "lieuDung": med["lieuDung"]!.text.trim(),
                              });
                            }
                          }

                          String? ngayKhamFormatted = selectedDate != null ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}" : null;

                          Navigator.pop(context);

                          final result = await context.read<DoctorAppointmentDetailViewModel>().completeAndPrescribe(
                            widget.appointmentId, 
                            chanDoanCtrl.text.trim(), 
                            ngayKhamFormatted, 
                            danhSachThuocData
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(result['message']),
                              backgroundColor: result['success'] ? Colors.green : Colors.red,
                            ));
                          }
                        },
                        child: const Text("HOÀN THÀNH & LƯU ĐƠN THUỐC", style: kButtonTextStyle), // 🌟 Chuẩn Text
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showViewPrescriptionBottomSheet(BuildContext context) {
    context.read<DoctorAppointmentDetailViewModel>().fetchPrescription(widget.appointmentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))), // 🌟 Bo 20
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Consumer<DoctorAppointmentDetailViewModel>(
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
                                  padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 10), // 🌟 Lề 20
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
                                        Text(formatDate(data['Ngay_tai_kham']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryColor)),
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
                                              borderRadius: BorderRadius.circular(kBorderRadiusSmall), // 🌟 Bo 12
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

  Widget _buildHistoryRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 85, child: Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(color: valueColor ?? kTextColor, fontSize: 13, fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorAppointmentDetailViewModel>();
    final appointment = vm.appointmentDetail;
    return Scaffold(
      backgroundColor: kLightCyanBg2, // 🌟 Đồng bộ màu nền
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
                      // PHẦN 1: HEADER - THÔNG TIN BỆNH NHÂN (Giữ form gốc bo 30)
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
                                    const Text("Chi tiết Ca Khám", style: kHeaderTextStyle),
                                    const SizedBox(width: 48), 
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (appointment['patientAvatar'] != null && appointment['patientAvatar'].toString().startsWith('http'))
                                          ? NetworkImage(appointment['patientAvatar'])
                                          : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
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
                                    ),

                                    Spacer(),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
                                      tooltip: 'Báo cáo bác sĩ',
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => ReportBottomSheet(
                                            targetId: appointment['Ma_nguoi_dung'],
                                            targetName: appointment['Ten_nguoi_dung'],
                                            targetType: 'Patient',
                                          ),
                                        );
                                      },
                                    ),

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
                      // NGƯỜI LIÊN HỆ 
                      // ==========================================
                      if (appointment['isRelative'] == 1) ...[
                        _buildSectionTitle("Người liên hệ (Chủ tài khoản)"),
                        _buildCardContainer(
                          child: Column(
                            children: [
                              _buildInfoRow("Họ và tên", appointment['contactName'] ?? 'Chưa rõ', isBoldValue: true),
                              const Divider(height: 20, color: kBorderCyan),
                              _buildInfoRow("Điện thoại", appointment['contactPhone'] ?? 'Chưa cập nhật', valueColor: kPrimaryColor, isBoldValue: true),
                              const Divider(height: 20, color: kBorderCyan),
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
                            const Divider(height: 20, color: kBorderCyan),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.access_time_filled, color: kPrimaryColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(formatDate(appointment['startTime']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor)),
                                      const SizedBox(height: 4),
                                      Text("${formatTime(appointment['startTime'])} - ${formatTime(appointment['endTime'])}", style: const TextStyle(color: kGreyTextColor)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Divider(height: 25, color: kBorderCyan),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(appointment['type'] == 'offline' ? Icons.meeting_room : Icons.videocam, color: Colors.redAccent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    appointment['type'] == 'offline' ? "Khám trực tiếp tại phòng khám" : "Khám trực tuyến (Video Call)", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor)
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 25, color: kBorderCyan),
                            _buildInfoRow("Dịch vụ khám", appointment['selectedServices'] ?? 'Đang cập nhật', isBoldValue: true, valueColor: kPrimaryColor),
                            
                            // THÔNG TIN THANH TOÁN
                            const Divider(height: 25, color: kBorderCyan),
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
                        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50, 
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall), // 🌟 Bo 12
                            border: Border.all(color: Colors.red.shade200)
                          ),
                          child: Text(
                            (appointment['symptoms'] == null || appointment['symptoms'].toString().trim().isEmpty) 
                                ? 'Không có ghi chú triệu chứng.' 
                                : appointment['symptoms'], 
                            style: const TextStyle(color: kTextColor, height: 1.4, fontSize: 15)
                          ),
                        ),
                      ),

                      // ==========================================
                      // PHẦN 4: HỒ SƠ Y TẾ VÀ LỊCH SỬ BỆNH ÁN
                      // ==========================================
                      _buildSectionTitle("Hồ sơ y tế / Tiền sử bệnh"),
                      _buildCardContainer(
                        child: Column(
                          children: [
                            _buildInfoRow("Nhóm máu", appointment['bloodType'] ?? 'Chưa cập nhật', isBoldValue: true, valueColor: Colors.red),
                            const Divider(height: 20, color: kBorderCyan),
                            _buildInfoRow("Dị ứng", appointment['allergies'] ?? 'Không ghi nhận', isBoldValue: appointment['allergies'] != null),
                            const Divider(height: 20, color: kBorderCyan),
                            _buildInfoRow("Bệnh nền", appointment['backgroundDiseases'] ?? 'Không ghi nhận', isBoldValue: appointment['backgroundDiseases'] != null),
                            
                            // 🌟 NÚT XEM LỊCH SỬ BỆNH ÁN
                            const Divider(height: 20, color: kBorderCyan),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimaryColor, 
                                  side: const BorderSide(color: kPrimaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Bo 12
                                ),
                                onPressed: () => _showMedicalHistory(context),
                                icon: const Icon(Icons.history, size: 20),
                                label: const Text("Xem lịch sử khám bệnh", style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomSheet: vm.isLoading || appointment == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 15),
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
    final vm = context.read<DoctorAppointmentDetailViewModel>();

    // 🌟 HÀM XỬ LÝ CHUNG CHO NÚT DUYỆT/TỪ CHỐI
    void handleUpdateStatus(String action) async {
      final res = await vm.updateStatus(widget.appointmentId, action);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] ? Colors.green : Colors.red,
        ));
      }
    }

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _buildOutlinedButton('Từ chối', Colors.red, () => handleUpdateStatus('reject')),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildSolidButton('Xác nhận', Icons.check_circle, Colors.green, () => handleUpdateStatus('confirm')),
          ),
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
          // 🌟 CHIA ĐÔI HÀNG NÚT: BÁO VẮNG VÀ KÊ ĐƠN
          Row(
            children: [
              Expanded(
                child: _buildOutlinedButton('Báo vắng', Colors.orange, () async {
                  final startTime = DateTime.parse(appointment['startTime']).toLocal();
                  // Kiểm tra thời gian: Chỉ được báo vắng sau khi giờ khám đã qua 15 phút
                  if (DateTime.now().isAfter(startTime.add(const Duration(minutes: 15)))) {
                    final res = await vm.updateStatusAbsent(widget.appointmentId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res['message']),
                        backgroundColor: res['success'] ? Colors.green : Colors.red,
                      ));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chỉ báo vắng khi giờ khám qua tối thiểu 15 phút!'),
                        backgroundColor: Colors.orange,
                      )
                    );
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSolidButton('Kê đơn', Icons.edit_document, kPrimaryColor, () {
                  _showPrescriptionBottomSheet(context);
                }),
              ),
            ],
          ),
        ],
      );
    }

    if (status == 'done') {
      return SizedBox(
        width: double.infinity,
        child: _buildOutlinedButton('Xem lại đơn thuốc', kPrimaryColor, () {
          _showViewPrescriptionBottomSheet(context);
        })
      );
    }

    return const SizedBox.shrink(); 
  }

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
        border: Border.all(color: kBorderCyan),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
      ),
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
      style: OutlinedButton.styleFrom(
        foregroundColor: color, 
        side: BorderSide(color: color), 
        padding: const EdgeInsets.symmetric(vertical: 14), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)) // 🌟 Bo 12
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSolidButton(String text, IconData icon, Color bgColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor, 
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(vertical: 14), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // 🌟 Bo 12 
        elevation: 0
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}