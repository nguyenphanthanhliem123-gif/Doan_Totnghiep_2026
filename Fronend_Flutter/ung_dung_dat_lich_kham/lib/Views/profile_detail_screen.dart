import 'dart:io'; // 🚀 ĐÃ THÊM: Để làm việc với File ảnh
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 🚀 ĐÃ THÊM: Thư viện chọn ảnh
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/user_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/update_profile_screen.dart';
import '../constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  String? _maNguoiDung;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
    if (!mounted) return;
    setState(() { _maNguoiDung = id; });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // 🚀 ĐÃ THÊM: Hàm kích hoạt chọn ảnh và đẩy lên Backend
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Hiển thị hộp thoại cho người dùng chọn nguồn ảnh (Bộ sưu tập hoặc Máy ảnh)
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // Bạn có thể đổi thành ImageSource.camera tùy ý
      imageQuality: 80,            // Nén chất lượng ảnh xuống 80% cho nhẹ server
    );

    if (pickedFile != null) {
      setState(() { _isLoading = true; }); // Hiện vòng xoay chờ đợi

      final profileVM = context.read<ProfileViewModel>();
      File file = File(pickedFile.path);

      // Gọi hàm upload lên Backend
      await profileVM.uploadingAvatar(file);
      bool? isSuccess = profileVM.uploadAvatar;

      if (isSuccess! && _maNguoiDung != null) {
        final maNguoiDungInt = int.tryParse(_maNguoiDung!);
        if (maNguoiDungInt != null) {
          // Tải lại dữ liệu mới từ Database để cập nhật link ảnh đại diện vừa thay đổi
          await profileVM.getUserProfile(maNguoiDungInt);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải ảnh lên thất bại. Vui lòng thử lại!'), backgroundColor: Colors.red),
          );
        }
      }

      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hồ sơ cá nhân',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading || profileViewModel.isLoading || user == null
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // ---------------- Phần Ảnh đại diện (ĐÃ CẬP NHẬT) ----------------
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            border: Border.all(color: kPrimaryColor, width: 3),
                            image: DecorationImage(
                              fit: BoxFit.cover, 
                              // 💡 Kiểm tra nếu trong model user có link ảnh từ DB thì hiển thị, nếu không thì lấy ảnh mặc định
                              // Chú ý: Hãy kiểm tra lại chính xác tên thuộc tính chứa ảnh trong UserModel của bạn (Vd: user.avatar hoặc user.anhDaiDien)
                              image: (user.avatar != null && user.avatar!.isNotEmpty)
                                  ? NetworkImage(user.avatar!)
                                  : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                            ),
                          ),
                        ),
                        // Nút tròn nhỏ có hình Camera đè góc dưới bên phải ảnh đại diện
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImage, // Bấm vào để kích hoạt chọn ảnh
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: kPrimaryColor,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ---------------- Phần Thông tin người dùng ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadOnlyField(label: 'Họ và Tên', value: user.fullName, icon: Icons.person_outline),
                        _buildReadOnlyField(label: 'Email', value: user.email, icon: Icons.email_outlined),
                        
                        _buildReadOnlyField(
                          label: 'Số điện thoại', 
                          value: (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : 'Chưa cập nhật', 
                          icon: Icons.phone_android_outlined
                        ),

                        _buildReadOnlyField(
                          label: 'Ngày sinh',
                          value: user.dob != null ? "${user.dob!.day.toString().padLeft(2, '0')}/${user.dob!.month.toString().padLeft(2, '0')}/${user.dob!.year}" : '',
                          icon: Icons.calendar_month,
                        ),
                        _buildReadOnlyField(label: 'Giới tính', value: user.gender == 1 ? 'Nam': 'Nữ', icon: Icons.wc_outlined),
                        _buildReadOnlyField(label: 'Địa chỉ', value: user.address ?? '', icon: Icons.location_on_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- Nút Hành động ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UpdateProfileScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor, minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Cập nhật hồ sơ', style: kButtonTextStyle),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value, readOnly: true,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            fillColor: kInputBackgroundColor, filled: true, suffixIcon: Icon(icon, color: kGreyTextColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}