import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/change_password_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/health_record_menu_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/profile_detail_screen.dart';
import '../constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget{
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  String? _maNguoiDung;
  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    print("=== BẮT ĐẦU LOAD ===");
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();
    print("=== ID: $id");
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
  }

  @override
  Widget build(BuildContext context) {
    if (_maNguoiDung == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // 2. LẮNG NGHE SỰ THAY ĐỔI TỪ PROFILE_VIEWMODEL
    final profileVM = context.watch<ProfileViewModel>();
    final user = profileVM.userProfile;

    print('=== USER: $user');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Thông tin cá nhân', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      // 3. XỬ LÝ TRẠNG THÁI LOADING VÀ HIỂN THỊ DỮ LIỆU
      body: profileVM.isLoading 
          ? const Center(child: CircularProgressIndicator()) // Hiện vòng xoay khi đang tải API
          : user == null 
              ? const Center(child: Text("Không thể tải thông tin tài khoản.")) // Nếu lỗi hoặc không có dữ liệu
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(
                        children: [
                          // 4. ĐỔ ẢNH ĐẠI DIỆN ĐỘNG TỪ API HOẶC ẢNH MẶC ĐỊNH
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                                ? NetworkImage(user.avatar!) // Nếu có link ảnh từ API thì load từ internet
                                : const AssetImage('assets/images/profile_picture.png') as ImageProvider, // Nếu trống thì dùng ảnh local
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Đổ tên, số điện thoại và email động từ model
                                Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(user.email, style: const TextStyle(color: kGreyTextColor, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildOptionItem(Icons.person_outline, 'Hồ sơ cá nhân', true, (){
                            if(!context.mounted) return;
                            if(user.address != null && user.dob != null && user.gender != null)
                            {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ProfileDetailScreen())
                              );
                            }else{
                              
                            }
                          }),
                          _buildOptionItem(Icons.health_and_safety_outlined, 'Hồ sơ sức khỏe', true, (){
                            if(!mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => HealthRecordListScreen())
                            );
                          }),
                          _buildOptionItem(Icons.payment, 'Phương thức thanh toán', true, (){}),
                          _buildOptionItem(Icons.lock_outline, 'Quản lý mật khẩu', true, (){
                            if(!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => ChangePasswordScreen())
                            );
                          }),
                          _buildOptionItem(Icons.person_remove, 'Xóa tài khoản', false, (){
                            _showConfirmBottomSheet(context, isDeleteAccount: true);
                          }),
                          _buildOptionItem(Icons.logout, 'Đăng xuất', false, (){
                            _showConfirmBottomSheet(context, isDeleteAccount: false);
                          })
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, bool turnOnArr, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child:
      InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
              const SizedBox(width: 15),
              Expanded(child: Text(title, style: kLabelTextStyle)),
            if(turnOnArr)
              const Icon(Icons.arrow_forward_ios, size: 15, color: kGreyTextColor),
          ],
        ),
      )
    );
  }

  void _showConfirmBottomSheet(BuildContext context, {required bool isDeleteAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
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
                      child: const Text('Hủy', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Đóng BottomSheet trước

                        if (isDeleteAccount) {
                          // LẤY ID RA ĐỂ GỌI HÀM XÓA TÀI KHOẢN
                          final userId = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
                          
                          if (userId != null) {
                            if (!context.mounted) return;
                            
                            // Gọi hàm xóa tài khoản từ ViewModel
                            final result = await Provider.of<AuthViewModel>(context, listen: false).deleteAccount(userId);
                            
                            if (!context.mounted) return;
                            
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tài khoản của bạn đã được vô hiệu hóa thành công!')),
                              );
                              // Điều hướng về Login và xóa lịch sử màn hình
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
                          // LOGIC ĐĂNG XUẤT 
                          await Provider.of<AuthViewModel>(context, listen: false).logout();
                          
                          if (!context.mounted) return;
                          
                          // Điều hướng đưa người dùng bay thẳng về màn hình Đăng nhập
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDeleteAccount ? Colors.red : kPrimaryColor, // Đổi màu đỏ nếu là nút Xóa cho nguy hiểm
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