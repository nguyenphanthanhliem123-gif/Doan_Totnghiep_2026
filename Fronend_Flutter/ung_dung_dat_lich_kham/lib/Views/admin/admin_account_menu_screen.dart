import 'package:flutter/material.dart';
import '../../Constants/ui_constants.dart';
import 'admin_doctor_list_screen.dart';
import 'admin_patient_list_screen.dart';

class AdminAccountMenuScreen extends StatelessWidget {
  const AdminAccountMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý Tài khoản',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Vui lòng chọn loại tài khoản bạn muốn quản trị hệ thống:',
                style: TextStyle(color: kGreyTextColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              
              // 1. NÚT CHUYỂN HƯỚNG QUẢN LÝ BÁC SĨ
              _buildMenuCard(
                context: context,
                title: 'Quản lý Bác sĩ',
                subtitle: 'Xem danh sách, tìm kiếm, khóa/mở khóa tài khoản bác sĩ',
                icon: Icons.medical_services_rounded,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDoctorListScreen()),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // 2. NÚT CHUYỂN HƯỚNG QUẢN LÝ BỆNH NHÂN
              _buildMenuCard(
                context: context,
                title: 'Quản lý Bệnh nhân',
                subtitle: 'Xem danh sách, lịch sử đặt lịch và chi tiết lịch hẹn bệnh nhân',
                icon: Icons.people_alt_rounded,
                iconColor: kPrimaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPatientListScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget thiết kế khối Button dạng Card hiện đại
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: kGreyTextColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            children: [
              // Vòng tròn chứa Icon bọc màu mờ nhạt sang trọng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              // Phần chữ Text nội dung thông tin công việc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kGreyTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Mũi tên chỉ hướng sang phải thúc đẩy click hành động
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: kGreyTextColor.withOpacity(0.4),
                size: 16,
              )
            ],
          ),
        ),
      ),
    );
  }
}