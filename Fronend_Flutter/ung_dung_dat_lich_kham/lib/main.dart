import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/ViewModels/doctor_clinic_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_report_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_service_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/notification_viewmodel.dart';
import 'dart:ui';
import 'package:ung_dung_dat_lich_kham/ViewModels/payment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/schedule_config_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_service_viewmodel.dart';
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
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_viewmodel.dart';
import 'views/admin/admin_login_screen.dart';

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
        ChangeNotifierProvider(create: (_) => NotificationViewmodel()),
        // --- ViewModel của bác sĩ ---
        ChangeNotifierProvider(create: (_) => DoctorAppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentListViewModel()),
        ChangeNotifierProvider(create: (_) => AppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentDetailViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorClinicViewmodel()),
        ChangeNotifierProvider(create: (_) => DoctorServiceViewModel()),
        ChangeNotifierProvider(create: (_) => ScheduleConfigViewmodel()),
        ChangeNotifierProvider(create: (_) => DoctorServiceViewModel()),
        // --- ViewModel của Admin ---
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => AdminReportViewModel()),
        ChangeNotifierProvider(create: (_) => AdminServiceViewModel()),
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
        //home: const LoginScreen(),
        home: const AdminLoginScreen(),
      ),
    );
  }
}