import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
// import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart'; // Import ViewModel quản lý API bác sĩ của bạn
import 'update_doctor_profile_screen.dart'; // Import màn hình Update vừa tạo ở trên

class DoctorProfileDetailScreen extends StatefulWidget {
  final int userId; 
  const DoctorProfileDetailScreen({super.key, required this.userId});

  @override
  State<DoctorProfileDetailScreen> createState() => _DoctorProfileDetailScreenState();
}

class _DoctorProfileDetailScreenState extends State<DoctorProfileDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  // Hàm tải dữ liệu
  Future<void> _fetchDoctorData() async {
    setState(() { _isLoading = true; });

    // 1. Lấy thông tin cơ bản (Avatar, Tên, Email...) từ ProfileViewModel
    await context.read<ProfileViewModel>().getUserProfile(widget.userId);

    // 2. Lấy thông tin chuyên môn (Học vị, Chuyên khoa, Kinh nghiệm) từ DoctorViewModel
    // (Bạn cần viết thêm hàm getDoctorDetail trong DoctorViewModel gọi API /api/doctors/:id)
    // await context.read<DoctorViewModel>().getDoctorDetail(widget.userId);

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc dữ liệu từ ViewModels
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    // Giả sử bạn đã có model DoctorInfo trong DoctorViewModel
    // final doctorInfo = context.watch<DoctorViewModel>().doctorInfo; 

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
      body: _isLoading || profileViewModel.isLoading || user == null
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
                        _buildReadOnlyField(label: 'Học vị / Chức danh', value: 'ThS. BS (Dữ liệu mẫu)', icon: Icons.school_outlined), // vd: doctorInfo.hocVi
                        _buildReadOnlyField(label: 'Chuyên khoa', value: 'Khoa Nội (Dữ liệu mẫu)', icon: Icons.local_hospital_outlined),
                        _buildReadOnlyField(label: 'Số năm kinh nghiệm', value: '10 năm (Dữ liệu mẫu)', icon: Icons.work_history_outlined),
                        _buildReadOnlyField(label: 'Mô tả bản thân', value: 'Bác sĩ tận tâm, yêu nghề... (Dữ liệu mẫu)', icon: Icons.description_outlined),
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
                            builder: (context) => UpdateDoctorProfileScreen(userId: widget.userId),
                          )
                        ).then((_) {
                          // Hàm này sẽ chạy khi bác sĩ từ trang Update bấm mũi tên <- quay lại trang này
                          // Gọi hàm tải lại để cập nhật ảnh và thông tin mới nhất lên màn hình
                          _fetchDoctorData();
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