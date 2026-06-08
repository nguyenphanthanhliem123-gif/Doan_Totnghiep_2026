import 'package:flutter/material.dart';
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
    const ProfileScreen(),
    const UpdateProfileScreen(),
    const ChangePasswordScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Thông tin'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Cập nhật'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Mật khẩu'),
        ],
      ),
    );
  }
}