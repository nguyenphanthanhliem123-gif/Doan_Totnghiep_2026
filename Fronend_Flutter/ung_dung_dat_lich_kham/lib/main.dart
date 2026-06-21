import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:ung_dung_dat_lich_kham/ViewModels/payment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/search_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/login_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/clinic_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/review_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/booking_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_list_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_detail_viewmodel.dart';

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
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HealthRecordViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorViewModel()),
        ChangeNotifierProvider(create: (_) => ClinicViewModel()),
        ChangeNotifierProvider(create: (_) => SpecialtyViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => ReviewViewModel()),
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => AppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewmodel()),
        // --- ViewModel của bác sĩ ---
        ChangeNotifierProvider(create: (_) => DoctorAppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentListViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentDetailViewModel()),
      ],
      child: MaterialApp(
        title: 'Hệ thống đặt lịch khám bệnh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C3C9)),
        ),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
        home: const LoginScreen(),
      ),
    );
  }
}