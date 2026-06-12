import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
//import 'package:ung_dung_dat_lich_kham/ViewModels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/Views/health_record_menu_screen.dart';
// import 'package:ung_dung_dat_lich_kham/Views/main_screen.dart';
// import 'viewmodels/profile_viewmodel.dart'; 
// import 'viewmodels/health_record_viewmodel.dart'; 
import 'viewmodels/auth_viewmodel.dart';
import 'views/login_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        // ChangeNotifierProvider(create: (_) => HealthRecordViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
<<<<<<< HEAD
        ChangeNotifierProvider(create: (_) => HealthRecordViewModel())
=======
        ChangeNotifierProvider(create: (_) => DoctorViewModel()),
>>>>>>> 4ec7b5c7bf610b01c26697352281e98b58fc815e
      ],
      child: MaterialApp(
        title: 'Hệ thống đặt lịch khám bệnh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C3C9)),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}