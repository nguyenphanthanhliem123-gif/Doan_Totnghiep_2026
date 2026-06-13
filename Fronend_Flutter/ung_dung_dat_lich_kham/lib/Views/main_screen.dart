import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/global_search_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/specialty_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/views/health_record_menu_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/profile_detail_screen.dart';
//import 'package:ung_dung_dat_lich_kham/Views/update_health_record_screen.dart'; (Lỗi không thấy file này, tạm comment lại để chạy được)
import 'profile_screen.dart';
import 'update_profile_screen.dart';
import 'change_password_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    //const HealthRecordMenuScreen(),
    //const HealthRecordMenuScreen(),
    const ProfileScreen(),
    const DoctorListScreen(),
    const SpecialtyListScreen(),
    const GlobalSearchScreen(),
    //const UpdateProfileScreen(),
    //const ChangePasswordScreen(),
    //const UpdateHealthRecordScreen(),
    //const Scaffold(body: Center(child: Text('Màn hình Lịch khám (Chưa cấu hình)'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryColor,   // Màu xanh khi được chọn
        unselectedItemColor: kGreyTextColor, // Màu xám khi không chọn
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
        ],
      ),
    );
  }
}