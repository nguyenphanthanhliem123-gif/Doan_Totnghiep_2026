import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../viewmodels/clinic_viewmodel.dart';
import '../viewmodels/review_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../constants/ui_constants.dart'; 
import '../models/doctor_detail_model.dart';
import 'doctor_review_screen.dart'; 
import 'booking_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final int doctorId; 
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  int _currentImageIndex = 0;

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().fetchDoctorDetail(widget.doctorId); 
      context.read<ClinicViewModel>().fetchClinicDetail(widget.doctorId); 
      context.read<ReviewViewModel>().clearReviews(); 
      context.read<ReviewViewModel>().fetchReviews(widget.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetail;

    final clinicVM = context.watch<ClinicViewModel>();
    final clinic = clinicVM.clinicDetail;
    
    final reviewVM = context.watch<ReviewViewModel>();
    final String avgRating = reviewVM.reviews.isEmpty ? "0.0" : reviewVM.averageRating.toStringAsFixed(1);
    final String reviewCount = reviewVM.reviews.isEmpty ? "Chưa có" : "${reviewVM.reviews.length}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: doctorVM.isLoading || clinicVM.isLoading
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
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
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
                                              _buildBadge(Icons.star, avgRating), 
                                              const SizedBox(width: 10),
                                              _buildBadge(
                                                Icons.chat, 
                                                "$reviewCount đánh giá",
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const DoctorReviewScreen()),
                                                  );
                                                }
                                              ),
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

                      const SizedBox(height: 25),

                      // ==========================================
                      // PHẦN 2: THÔNG TIN BÁC SĨ
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Giới thiệu bản thân"),
                            Text(
                              doctor.description ?? "Bác sĩ chưa cập nhật thông tin giới thiệu.",
                              style: const TextStyle(color: kTextColor, height: 1.5),
                            ),
                            const SizedBox(height: 25),

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

                            // CẬP NHẬT: Đổi tiêu đề cho phù hợp với 7 ngày
                            _buildSectionTitle("Lịch làm việc 7 ngày tới"),
                            _buildExpandableSchedule(doctor.schedules),

                            const SizedBox(height: 35),
                          ],
                        ),
                      ),

                      // ==========================================
                      // PHẦN 3: THÔNG TIN PHÒNG KHÁM
                      // ==========================================
                      Container(
                        color: kInputBackgroundColor.withOpacity(0.5), 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        child: clinic == null 
                        ? const Center(child: Text("Đang tải thông tin cơ sở y tế..."))
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Thông tin Cơ sở Y tế"),
                            const SizedBox(height: 10),

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

                            if (clinic.description != null && clinic.description!.isNotEmpty)
                              Text(
                                clinic.description!,
                                style: const TextStyle(color: kTextColor, fontSize: 14, height: 1.5),
                              ),
                            
                            const SizedBox(height: 40), 
                          ],
                        ),
                      )
                    ],
                  ),
                ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () async {
                final profileVM = context.read<ProfileViewModel>();
                
                // Nếu sđt bị null hoặc rỗng -> Chặn lại và báo lỗi
                if (profileVM.userProfile?.phone == null || profileVM.userProfile!.phone!.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng cập nhật Số điện thoại trong tab Hồ Sơ cá nhân trước khi đặt lịch!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return; // Dừng luôn, không cho nhảy sang trang BookingScreen
                }

                // Nếu đã có SĐT thì cho đi tiếp bình thường
                final isSuccess = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(doctor: doctor!), 
                  ),
                );
                if (isSuccess == true && context.mounted) {
                  context.read<DoctorViewModel>().fetchDoctorDetail(widget.doctorId); 
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text(
                "Đặt lịch khám",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
    );
  }

  // ==========================================
  // CẬP NHẬT: HIỂN THỊ CỐ ĐỊNH 7 NGÀY TIẾP THEO
  // ==========================================
  Widget _buildExpandableSchedule(List<DoctorScheduleModel> schedules) {
    // Lấy ngày giờ hiện tại
    final DateTime now = DateTime.now();
    
    // Tạo danh sách 7 ngày liên tiếp tính từ hôm nay
    final List<DateTime> next7Days = List.generate(7, (index) => now.add(Duration(days: index)));

    return Column(
      children: next7Days.map((currentDate) {
        // Format ngày hiện tại thành chuỗi yyyy-MM-dd để so sánh với Database
        String dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

        // Tìm trong danh sách API xem ngày này bác sĩ có lịch không
        var matchedSchedules = schedules.where((s) {
          // Xử lý cắt chuỗi nếu API trả về dạng ISO (VD: 2024-06-19T00:00:00.000Z)
          String sDate = s.date.length >= 10 ? s.date.substring(0, 10) : s.date;
          return sDate == dateString;
        });

        DoctorScheduleModel? dailySchedule = matchedSchedules.isNotEmpty ? matchedSchedules.first : null;

        // Xử lý hiển thị "Thứ" trong tuần
        List<String> weekdays = ["", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"];
        
        // Nếu là ngày hôm nay thì in chữ "Hôm nay" thay vì "Thứ..."
        String weekdayStr = (currentDate.day == now.day && currentDate.month == now.month) 
            ? "Hôm nay" 
            : weekdays[currentDate.weekday];
            
        String dateDisplay = "$weekdayStr (${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')})";

        // Phân loại slot Sáng / Chiều nếu có lịch
        List<DoctorTimeSlotModel> morningSlots = [];
        List<DoctorTimeSlotModel> afternoonSlots = [];

        if (dailySchedule != null) {
          for (var slot in dailySchedule.slots) {
            if (slot.status != 'locked') {
              int hour = int.tryParse(slot.time.split(':')[0]) ?? 0;
              if (hour < 12) {
                morningSlots.add(slot);
              } else {
                afternoonSlots.add(slot);
              }
            }
          }
        }

        bool hasSlots = morningSlots.isNotEmpty || afternoonSlots.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
            child: ExpansionTile(
              title: Text(
                hasSlots ? "$dateDisplay - Có lịch khám" : "$dateDisplay - Không có lịch",
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: hasSlots ? kTextColor : kGreyTextColor, // Màu xám nếu không có lịch
                  fontSize: 14
                ),
              ),
              iconColor: kPrimaryColor,
              collapsedIconColor: Colors.grey,
              childrenPadding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasSlots)
                  const Text("Bác sĩ không có ca khám nào trong ngày này.", style: TextStyle(color: kGreyTextColor, fontStyle: FontStyle.italic)),

                // Render list ca Sáng
                if (morningSlots.isNotEmpty) ...[
                  const Text("☀️ Ca Sáng", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: morningSlots.map((slot) {
                      bool isBooked = slot.status == 'booked';
                      return Text(
                        "${slot.time}${isBooked ? ' (Đã đặt)' : ''}", 
                        style: TextStyle(
                          color: isBooked ? Colors.grey.shade400 : Colors.black87,
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                          fontSize: 13,
                        )
                      );
                    }).toList(),
                  ),
                  if (afternoonSlots.isNotEmpty) const SizedBox(height: 15),
                ],
                
                // Render list ca Chiều
                if (afternoonSlots.isNotEmpty) ...[
                  const Text("🌙 Ca Chiều", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: afternoonSlots.map((slot) {
                      bool isBooked = slot.status == 'booked';
                      return Text(
                        "${slot.time}${isBooked ? ' (Đã đặt)' : ''}", 
                        style: TextStyle(
                          color: isBooked ? Colors.grey.shade400 : Colors.black87,
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                          fontSize: 13,
                        )
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- CÁC WIDGET HỖ TRỢ GIỮ NGUYÊN ---
  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBadge(IconData icon, String text, {VoidCallback? onTap}) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: onTap != null ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, color: kPrimaryColor, size: 10),
          ]
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: content,
        ),
      );
    }
    return content;
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