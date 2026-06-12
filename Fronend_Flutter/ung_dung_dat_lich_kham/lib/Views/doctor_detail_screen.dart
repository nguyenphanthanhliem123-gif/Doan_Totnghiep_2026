import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../constants/ui_constants.dart'; 
import '../models/doctor_detail_model.dart';

class DoctorDetailScreen extends StatefulWidget {
  // TODO: Mở comment dòng dưới khi tích hợp luồng điều hướng từ trang Danh sách
  // final int doctorId; 
  // const DoctorDetailScreen({super.key, required this.doctorId});

  const DoctorDetailScreen({super.key});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  String formatDateStr(String dateString) {
    try {
      final parts = dateString.split('-'); // Tách 2026-06-12
      return "${parts[2]}/${parts[1]}";   // Trả về 12/06
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    // Tạm thời sử dụng ID cố định để kiểm thử giao diện và kết nối API.
    // Chuyển sang widget.doctorId khi hoàn thiện luồng danh sách.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().fetchDoctorDetail(1); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetail;

    return Scaffold(
      backgroundColor: Colors.white,
      body: doctorVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : doctor == null
              ? const Center(child: Text('Không thể tải thông tin bác sĩ'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // PHẦN 1: HEADER - THÔNG TIN CƠ BẢN
                      // ==========================================
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Thanh điều hướng và các nút thao tác
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Row(
                                      children: [
                                        _buildActionIcon(Icons.phone),
                                        const SizedBox(width: 10),
                                        _buildActionIcon(Icons.videocam),
                                        const SizedBox(width: 10),
                                        _buildActionIcon(Icons.chat_bubble_outline),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Chi tiết định danh bác sĩ
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    // Ảnh đại diện
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (doctor.avatar != null && doctor.avatar!.isNotEmpty)
                                          ? NetworkImage(doctor.avatar!)
                                          : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Tên bác sĩ
                                          Text(
                                            doctor.fullName,
                                            style: kHeaderTextStyle.copyWith(fontSize: 18),
                                          ),
                                          const SizedBox(height: 5),
                                          
                                          // Học vị
                                          Text(
                                            "Học vị: ${doctor.degree ?? 'Đang cập nhật'}",
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Chuyên khoa
                                          Text(
                                            "Chuyên khoa: ${doctor.specialtyName ?? 'Đang cập nhật'}",
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Chỉ số đánh giá và tương tác (Mock data)
                                          Row(
                                            children: [
                                              _buildBadge(Icons.star, "5.0"),
                                              const SizedBox(width: 10),
                                              _buildBadge(Icons.chat, "3+"),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Kinh nghiệm làm việc
                                          Text(
                                            "${doctor.yearsOfExperience ?? 0} năm kinh nghiệm",
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
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

                      // Thông tin khung giờ làm việc (Mock data)
                      Transform.translate(
                        offset: const Offset(0, -25),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==========================================
                      // PHẦN 2: THÔNG TIN CHI TIẾT
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Giới thiệu bản thân
                            _buildSectionTitle("Giới thiệu bản thân"),
                            Text(
                              doctor.description ?? "Bác sĩ chưa cập nhật thông tin giới thiệu.",
                              style: const TextStyle(color: kTextColor, height: 1.5),
                            ),
                            const SizedBox(height: 25),

                            // Danh sách dịch vụ khám (Mock data)
                            _buildSectionTitle("Dịch vụ khám"),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: doctor.services.isEmpty
                                  ? const Text("Chưa có thông tin dịch vụ.", style: TextStyle(color: kGreyTextColor))
                                  : Column(
                                      children: doctor.services.map((service) {
                                        return _buildServiceRow(
                                          service.name, 
                                          formatCurrency(service.price)
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 25),

                            // Lịch làm việc theo ngày
                            _buildSectionTitle("Lịch làm việc"),
                            if (doctor.schedules.isEmpty)
                              const Text("Bác sĩ hiện chưa có lịch làm việc.", style: TextStyle(color: kGreyTextColor))
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Danh sách ngày
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: doctor.schedules.map((schedule) {
                                        final isSelected = doctorVM.selectedDate == schedule.date;
                                        return GestureDetector(
                                          onTap: () => doctorVM.selectDate(schedule.date),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? kPrimaryColor : Colors.white,
                                              border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Text(
                                              formatDateStr(schedule.date),
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : kTextColor,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Danh sách khung giờ của ngày được chọn
                                  Builder(
                                    builder: (context) {
                                      // Tìm danh sách giờ của ngày đang chọn
                                      final currentSchedule = doctor.schedules.firstWhere(
                                        (s) => s.date == doctorVM.selectedDate,
                                        orElse: () => DoctorScheduleModel(date: '', slots: []),
                                      );

                                      if (currentSchedule.slots.isEmpty) {
                                        return const Text("Không có ca khám nào trong ngày này.", style: TextStyle(color: kGreyTextColor));
                                      }

                                      return Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: currentSchedule.slots.map((slot) {
                                          final isSelected = doctorVM.selectedSlot?.id == slot.id;
                                          final isAvailable = slot.status == 'available';

                                          Color boxColor;
                                          Color textColor;
                                          Color borderColor;
                                          TextDecoration? textDecoration;

                                          // Xử lý giao diện theo từng trạng thái cụ thể
                                          if (slot.status == 'booked') {
                                            boxColor = Colors.grey.shade200;
                                            textColor = Colors.grey.shade400;
                                            borderColor = Colors.transparent;
                                            textDecoration = TextDecoration.lineThrough;
                                          } else if (slot.status == 'locked') {
                                            boxColor = Colors.red.shade50;
                                            textColor = Colors.red.shade300;
                                            borderColor = Colors.red.shade100;
                                            textDecoration = TextDecoration.lineThrough;
                                          } else {
                                            // Trạng thái 'available'
                                            if (isSelected) {
                                              boxColor = kPrimaryColor;
                                              textColor = Colors.white;
                                              borderColor = kPrimaryColor;
                                              textDecoration = null;
                                            } else {
                                              boxColor = Colors.white;
                                              textColor = kTextColor;
                                              borderColor = Colors.grey.shade300;
                                              textDecoration = null;
                                            }
                                          }

                                          return GestureDetector(
                                            onTap: isAvailable ? () => doctorVM.selectSlot(slot) : null,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: boxColor,
                                                border: Border.all(color: borderColor),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                slot.time,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  decoration: textDecoration, 
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 25),

                            // Thông tin địa chỉ và nút chỉ đường
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Địa chỉ: ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                                Expanded(
                                  child: Text(
                                    "${doctor.clinicName ?? ''} - ${doctor.clinicAddress ?? 'Chưa cập nhật'}",
                                    style: const TextStyle(color: kTextColor),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text("Chỉ đường", style: TextStyle(color: Colors.white, fontSize: 12)),
                                )
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Hình ảnh bản đồ minh họa
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                'assets/images/map_placeholder.png', 
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Center(child: Text("Bản đồ Google Maps", style: TextStyle(color: kGreyTextColor))),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildServiceRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: kTextColor)),
          Text(price, style: const TextStyle(color: kTextColor)),
        ],
      ),
    );
  }
}