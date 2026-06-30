import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Views/home_screen.dart';
import 'profile_screen.dart';
import 'package:ung_dung_dat_lich_kham/views/appointment_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const AppointmentScreen(),
    const ProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch hẹn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}