import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Thêm import provider
import 'package:ung_dung_dat_lich_kham/Views/main_screen.dart';
import 'viewmodels/profile_viewmodel.dart'; // 2. Thêm import ViewModel của bạn
import 'Views/profile_screen.dart';

void main() {
  runApp(
    // 3. Bọc MyApp trong ChangeNotifierProvider để toàn bộ ứng dụng dùng được ViewModel
    ChangeNotifierProvider(
      create: (context) => ProfileViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống đặt lịch khám bệnh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(),
    );
  }
}