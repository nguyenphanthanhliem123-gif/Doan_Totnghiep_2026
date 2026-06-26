import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart'; // 🌟 Đã sửa path chữ viết hoa đồng bộ
import 'package:ung_dung_dat_lich_kham/Views/doctor/doctor_profile_detail_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor/doctor_schedule_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor/review_doctor_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor/update_clinic_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/change_password_screen.dart';
import 'package:ung_dung_dat_lich_kham/views/login_screen.dart';

class DoctorMenuScreen extends StatefulWidget {
  const DoctorMenuScreen({super.key});

  @override
  State<DoctorMenuScreen> createState() => DoctorMenuScreenState();
}

class DoctorMenuScreenState extends State<DoctorMenuScreen> {
  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    setState(() { _isLoading = true; });
    
    final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
    if (!mounted) return;

    if (id != null) {
      final parsedId = int.tryParse(id);
      setState(() {
        _userId = parsedId;
      });

      if (parsedId != null) {
        await context.read<ProfileViewModel>().getUserProfile(parsedId);
        if(!mounted) return;
        await context.read<DoctorViewModel>().fetchDoctorDetailForDoctor();
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetailForDoctor;
    
    final isPageLoading = _isLoading || profileViewModel.isLoading;

    return Scaffold(
      backgroundColor: kLightCyanBg2, // 🌟 Đồng bộ nền sạch đẹp
      body: isPageLoading || user == null || profileViewModel.isLoading || doctor == null || doctorVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              children: [
                // ---------------- 1. PHẦN HEADER DẠNG CONG ----------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, left: kDefaultPadding, right: kDefaultPadding, bottom: 30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kDarkCyan], // 🌟 Đồng bộ dải màu gradient chuẩn hệ thống
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30), // 🌟 Bo đáy 30 theo quy chuẩn Appbar cong của bạn dặn
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, ${user.fullName}!', 
                                style: kHeaderTextStyle.copyWith(fontSize: 22),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Chúc bạn một ngày làm việc tốt lành',
                                style: TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 23,
                              backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                                  ? NetworkImage(user.avatar!)
                                  : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 25),
                    physics: const BouncingScrollPhysics(), 
                    children: [
                      const Text(
                        'Quản lý phòng khám',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 15),

                      _buildMenuCard(
                        context: context,
                        title: 'Hồ sơ cá nhân',
                        subtitle: 'Xem và cập nhật thông tin của bạn',
                        icon: Icons.person_outline,
                        iconColor: kPrimaryColor, // 🌟 Thay màu chuẩn hệ thống
                        onTap: () {
                          if (_userId != null) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => DoctorProfileDetailScreen(),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không tìm thấy mã bác sĩ, vui lòng thử lại!')),
                            );
                          }
                        },
                      ),

                      _buildMenuCard(
                        context: context,
                        title: 'Thiết lập lịch làm việc',
                        subtitle: 'Tạo và quản lý ca khám bệnh',
                        icon: Icons.calendar_month_outlined,
                        iconColor: Colors.green,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorScheduleScreen()));
                        },
                      ),

                      _buildMenuCard(
                        context: context,
                        title: 'Đánh giá & Nhận xét',
                        subtitle: 'Xem phản hồi từ bệnh nhân',
                        icon: Icons.star_border_rounded,
                        iconColor: Colors.orange,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsDoctorScreen(doctorID: doctor.id)));
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Khác',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 15),

                      _buildMenuCard(
                        context: context,
                        title: 'Cơ sở y tế / Bệnh viện',
                        subtitle: 'Thông tin nơi bạn đang công tác',
                        icon: Icons.local_hospital_outlined,
                        iconColor: Colors.teal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => DoctorClinicSelectionScreen())
                          );
                        },
                      ),

                      _buildMenuCard(
                        context: context,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Đổi mật khẩu tài khoản',
                        icon: Icons.settings_outlined,
                        iconColor: Colors.blueGrey,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                        },
                      ),
                      
                      _buildMenuCard(
                        context: context,
                        title: 'Đăng xuất',
                        subtitle: 'Đăng xuất tài khoản',
                        icon: Icons.logout_outlined,
                        iconColor: Colors.redAccent,
                        onTap: () {
                          _showConfirmBottomSheet(context, isDeleteAccount: false);
                        },
                      ),
                      const SizedBox(height: 30), 
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc 20
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4), 
          ),
        ],
        border: Border.all(color: kBorderCyan),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          onTap: onTap, 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kBorderRadiusSmall), // Bo góc 12
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, color: kGreyTextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kLightCyanBg2,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: kGreyTextColor, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmBottomSheet(BuildContext context, {required bool isDeleteAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDeleteAccount 
                    ? 'Bạn có chắc chắn muốn xóa tài khoản này không?\nHành động này không thể hoàn tác.' 
                    : 'Bạn có muốn đăng xuất tài khoản này?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kPrimaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: kTextColor, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (isDeleteAccount) {
                          final userId = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
                          if (userId != null) {
                            if (!context.mounted) return;
                            final result = await Provider.of<AuthViewModel>(context, listen: false).deleteAccount(userId);
                            if (!context.mounted) return;
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tài khoản của bạn đã được vô hiệu hóa thành công!')),
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'])),
                              );
                            }
                          }
                        } else {
                          await Provider.of<AuthViewModel>(context, listen: false).logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDeleteAccount ? Colors.red : kPrimaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        isDeleteAccount ? 'Xóa' : 'Đăng xuất',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}