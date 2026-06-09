import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../Config/USER_ID.dart';

class ProfileScreen extends StatefulWidget{
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  

  @override
  Widget build(BuildContext context) {
    late user = Provider.of<ProfileViewModel>(context).getUserProfile(ma_nguoi_dung);

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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage('assets/images/profile_picture.png'),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(user.phone, style: const TextStyle(color: kGreyTextColor, fontSize: 14)),
                      const SizedBox(height: 2),
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
                _buildOptionItem(Icons.person_outline, 'Hồ sơ cá nhân', true, (){}),
                _buildOptionItem(Icons.health_and_safety_outlined, 'Hồ sơ sức khỏe', true, (){}),
                _buildOptionItem(Icons.payment, 'Phương thức thanh toán', true, (){}),
                _buildOptionItem(Icons.lock_outline, 'Quản lý mật khẩu', true, (){}),
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
                    ? 'Bạn có muốn xóa tài khoản này?' 
                    : 'Bạn có muốn đăng xuất tài khoản này?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  // 1. NÚT HỦY (Viền xanh, nền trắng)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx), // Đóng cửa sổ khi bấm Hủy
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kPrimaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 2. NÚT XÁC NHẬN (Nền màu xanh cyan chủ đạo)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (isDeleteAccount) {
                          // Xử lý logic xóa tài khoản ở đây (gọi ViewModel)
                          print("Thực hiện logic Xóa tài khoản");
                        } else {
                          // Xử lý logic đăng xuất ở đây (gọi ViewModel)
                          print("Thực hiện logic Đăng xuất");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
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