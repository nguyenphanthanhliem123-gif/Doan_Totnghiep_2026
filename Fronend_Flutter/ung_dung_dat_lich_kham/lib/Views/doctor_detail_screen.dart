import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../viewmodels/clinic_viewmodel.dart'; // Thêm ViewModel của Phòng khám
import '../constants/ui_constants.dart'; 
import '../models/doctor_detail_model.dart';

class DoctorDetailScreen extends StatefulWidget {
  // TODO: Mở comment dòng dưới khi tích hợp luồng điều hướng từ trang Danh sách
  final int doctorId; 
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  // Biến quản lý trang hiện tại của Slider ảnh phòng khám
  int _currentImageIndex = 0;

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  String formatDateStr(String dateString) {
    try {
      final parts = dateString.split('-');
      return "${parts[2]}/${parts[1]}";
    } catch (e) {
      return dateString;
    }
  }

  // Hàm hỗ trợ mở liên kết ngoài (Web, Phone, Google Maps)
  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết này!')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Tạm thời gọi ID 1 cho cả Bác sĩ và Phòng khám để test
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().fetchDoctorDetail(1); 
      context.read<ClinicViewModel>().fetchClinicDetail(1); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetail;

    final clinicVM = context.watch<ClinicViewModel>();
    final clinic = clinicVM.clinicDetail;

    return Scaffold(
      backgroundColor: Colors.white,
      body: doctorVM.isLoading || clinicVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : doctor == null
              ? const Center(child: Text('Không thể tải thông tin bác sĩ'))
              : SingleChildScrollView( // Cho phép toàn bộ trang kéo lên xuống mượt mà
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
                                          Text(
                                            doctor.fullName,
                                            style: kHeaderTextStyle.copyWith(fontSize: 18),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Học vị: ${doctor.degree ?? 'Đang cập nhật'}",
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Chuyên khoa: ${doctor.specialtyName ?? 'Đang cập nhật'}",
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _buildBadge(Icons.star, "5.0"),
                                              const SizedBox(width: 10),
                                              _buildBadge(Icons.chat, "3+"),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
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

                      const SizedBox(height: 25), // Đã xóa khung trắng Transform, chừa lại khoảng trống chuẩn

                      // ==========================================
                      // PHẦN 2: THÔNG TIN BÁC SĨ (Giới thiệu, Dịch vụ, Lịch)
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

                            // Danh sách dịch vụ khám
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
                                        return _buildServiceRow(service.name, formatCurrency(service.price));
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
                                  // Danh sách ngày ngang
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

                                  // Danh sách giờ lưới
                                  Builder(
                                    builder: (context) {
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

                                          Color boxColor = Colors.white;
                                          Color textColor = kTextColor;
                                          Color borderColor = Colors.grey.shade300;
                                          TextDecoration? textDecoration;

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
                                            if (isSelected) {
                                              boxColor = kPrimaryColor;
                                              textColor = Colors.white;
                                              borderColor = kPrimaryColor;
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
                            const SizedBox(height: 35),
                          ],
                        ),
                      ),

                      // ==========================================
                      // PHẦN 3: THÔNG TIN PHÒNG KHÁM (GỘP VÀO)
                      // ==========================================
                      Container(
                        color: kInputBackgroundColor.withOpacity(0.5), // Nhấn background nhẹ để tách biệt phần PK
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        child: clinic == null 
                        ? const Center(child: Text("Đang tải thông tin cơ sở y tế..."))
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Thông tin Cơ sở Y tế"),
                            const SizedBox(height: 10),

                            // Tên và Địa chỉ
                            Text(
                              clinic.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clinic.address ?? "Đang cập nhật địa chỉ...",
                                    style: const TextStyle(color: kTextColor, fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Các nút chức năng (Chỉ đường, Gọi điện, Website)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionButton(
                                  icon: Icons.directions,
                                  label: "Chỉ đường",
                                  color: Colors.blueAccent,
                                  onTap: () {
                                    if (clinic.lat != null && clinic.lng != null) {
                                      final url = 'https://www.google.com/maps/search/?api=1&query=${clinic.lat},${clinic.lng}';
                                      _launchExternalUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có tọa độ bản đồ.')));
                                    }
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.phone,
                                  label: "Gọi điện",
                                  color: Colors.green,
                                  onTap: () {
                                    if (clinic.phone != null && clinic.phone!.isNotEmpty) {
                                      _launchExternalUrl('tel:${clinic.phone}');
                                    }
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.language,
                                  label: "Website",
                                  color: Colors.orange,
                                  onTap: () {
                                    if (clinic.website != null && clinic.website!.isNotEmpty) {
                                      _launchExternalUrl(clinic.website!);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Slider Ảnh cơ sở vật chất
                            if (clinic.images.isNotEmpty) ...[
                              const Text("Cơ sở vật chất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 180,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: PageView.builder(
                                        itemCount: clinic.images.length,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentImageIndex = index;
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return Image.asset(
                                            clinic.images[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                                          );
                                        },
                                      ),
                                    ),
                                    if (clinic.images.length > 1)
                                      Positioned(
                                        bottom: 10,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(clinic.images.length, (index) {
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              width: _currentImageIndex == index ? 12 : 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _currentImageIndex == index ? kPrimaryColor : Colors.white.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Mô tả phòng khám
                            if (clinic.description != null && clinic.description!.isNotEmpty)
                              Text(
                                clinic.description!,
                                style: const TextStyle(color: kTextColor, fontSize: 14, height: 1.5),
                              ),
                            
                            const SizedBox(height: 40), // Cắt lề đáy cho thoáng
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  // Các Widget hỗ trợ (Giữ nguyên)
  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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
      child: Text(title, style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildServiceRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: kTextColor)),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 5),
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}