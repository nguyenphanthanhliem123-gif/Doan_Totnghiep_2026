import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/user_model.dart';
import 'package:ung_dung_dat_lich_kham/ViewModels/auth_viewmodel.dart';
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
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();

    if (!mounted) return;

    setState(() {
      _maNguoiDung = id;
    });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trực tiếp sự thay đổi dữ liệu từ ProfileViewModel
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Hồ sơ cá nhân', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body: profileViewModel.isLoading || user == null
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // ---------------- Phần Ảnh đại diện ----------------
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryColor, width: 3),
                        image: const DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ---------------- Phần Thông tin người dùng ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadOnlyField(
                          label: 'Họ và Tên',
                          value: user.fullName,
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          label: 'Email',
                          value: user.email,
                          icon: Icons.email_outlined,
                        ),
                        _buildReadOnlyField(
                          label: 'Ngày sinh',
                          // Định dạng hiển thị DD/MM/YYYY không cần cài thư viện intl
                          value: user.dob != null ? "${user.dob!.day.toString().padLeft(2, '0')}/${user.dob!.month.toString().padLeft(2, '0')}/${user.dob!.year}" : '',
                          icon: Icons.calendar_month,
                        ),
                        _buildReadOnlyField(
                          label: 'Giới tính',
                          value: user.gender == 1 ? 'Nam': 'Nữ',
                          icon: Icons.wc_outlined,
                        ),
                        _buildReadOnlyField(
                          label: 'Địa chỉ',
                          value: user.address ?? '',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- Nút Hành động (Đổi thành Quay lại) ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => UpdateProfileScreen())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
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

  // Hàm xây dựng các ô thông tin ở chế độ CHỈ ĐỌC (readOnly: true)
  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kLabelTextStyle),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true, // Khóa không cho nhập liệu từ bàn phím
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            fillColor: kInputBackgroundColor,
            filled: true,
            suffixIcon: Icon(icon, color: kGreyTextColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}