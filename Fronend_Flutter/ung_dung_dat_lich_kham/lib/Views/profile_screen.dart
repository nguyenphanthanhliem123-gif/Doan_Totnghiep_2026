import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu thay đổi từ ViewModel thông qua context.watch
    final user = context.watch<ProfileViewModel>().currentUser;

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
                _buildOptionItem(Icons.person_outline, 'Hồ sơ cá nhân'),
                _buildOptionItem(Icons.health_and_safety_outlined, 'Hồ sơ sức khỏe'),
                _buildOptionItem(Icons.payment, 'Phương thức thanh toán'),
                _buildOptionItem(Icons.lock_outline, 'Quản lý mật khẩu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: kLabelTextStyle)),
          const Icon(Icons.arrow_forward_ios, size: 15, color: kGreyTextColor),
        ],
      ),
    );
  }
}