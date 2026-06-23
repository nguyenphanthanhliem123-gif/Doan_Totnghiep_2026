import 'dart:ui';

import 'package:flutter/material.dart' hide Size;
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
// import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart'; // Import ViewModel quản lý API bác sĩ của bạn
import 'update_doctor_profile_screen.dart'; // Import màn hình Update vừa tạo ở trên

class DoctorProfileDetailScreen extends StatefulWidget {
  const DoctorProfileDetailScreen({super.key});

  @override
  State<DoctorProfileDetailScreen> createState() => _DoctorProfileDetailScreenState();
}

class _DoctorProfileDetailScreenState extends State<DoctorProfileDetailScreen> {
  bool _isLoading = true;
  String? _maNguoiDung;

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    setState(() { _isLoading = true; });
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();
    if (!mounted) return;

    setState(() {
      _maNguoiDung = id;
    });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      
      if (maNguoiDung != null) {
        if(!mounted) return;
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        await context.read<DoctorViewModel>().fetchDoctorDetailForDoctor();
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc dữ liệu từ ViewModels
    final profileViewModel = context.watch<ProfileViewModel>();
    final doctorViewModel = context.watch<DoctorViewModel>();
    final doctor = doctorViewModel.doctorDetailForDoctor;
    final user = profileViewModel.userProfile;

    print("=== _isLoading: $_isLoading | profileViewModel.isLoading: ${profileViewModel.isLoading} | doctorViewModel.isLoading: ${doctorViewModel.isLoading} | user: $user | doctor: $doctor");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.blueAccent, // Đổi thành kPrimaryColor của bạn
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Hồ sơ Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
          ),
        ),
      ),
      body: _isLoading || profileViewModel.isLoading || doctorViewModel.isLoading || user == null || doctor == null
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // ---------------- Phần Ảnh đại diện (Chỉ xem, không có icon camera) ----------------
                  Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.blueAccent, width: 3),
                        image: DecorationImage(
                          fit: BoxFit.cover, 
                          image: (user.avatar != null && user.avatar!.isNotEmpty)
                              ? NetworkImage(user.avatar!)
                              : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ---------------- Phần Thông tin ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Thông tin cá nhân ---
                        const Text("Thông tin cá nhân", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const SizedBox(height: 15),
                        _buildReadOnlyField(label: 'Họ và Tên', value: user.fullName, icon: Icons.person_outline),
                        _buildReadOnlyField(label: 'Email', value: user.email, icon: Icons.email_outlined),
                        _buildReadOnlyField(
                          label: 'Số điện thoại', 
                          value: (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : 'Chưa cập nhật', 
                          icon: Icons.phone_android_outlined
                        ),
                        
                        const Divider(height: 40, thickness: 1, color: Colors.black12),
                        
                        // --- Thông tin nghề nghiệp ---
                        const Text("Thông tin nghề nghiệp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const SizedBox(height: 15),

                        // 💡 THAY THẾ CHUỖI CỐ ĐỊNH BẰNG doctorInfo CỦA BẠN NHÉ
                        _buildReadOnlyField(label: 'Học vị / Chức danh', value: doctor.degree ?? '', icon: Icons.school_outlined), // vd: doctorInfo.hocVi
                        _buildReadOnlyField(label: 'Chuyên khoa', value: doctor.specialtyName, icon: Icons.local_hospital_outlined),
                        _buildReadOnlyField(label: 'Số năm kinh nghiệm', value: doctor.experienceYears.toString(), icon: Icons.work_history_outlined),
                        //_buildReadOnlyField(label: 'Mô tả bản thân', value: doctor., icon: Icons.description_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- Nút Hành động chuyển sang trang Cập nhật ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 🚀 Dùng Route Push kết hợp .then để lắng nghe sự kiện khi trang cập nhật bị tắt đi
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UpdateDoctorProfileScreen(userId: int.parse(_maNguoiDung ?? '0')),
                          )
                        ).then((_) {
                          _loadUserIdThenFetch();
                        });
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Cập nhật hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ---------------- Giao diện Ô Text chỉ đọc ----------------
  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value, 
            readOnly: true, // 🔒 Khóa không cho hiển thị bàn phím
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              fillColor: Colors.grey.shade100, // Đổ nền xám nhạt để user biết là ô không nhập được
              filled: true, 
              suffixIcon: Icon(icon, color: Colors.grey.shade600),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}