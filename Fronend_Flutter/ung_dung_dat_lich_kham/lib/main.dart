import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_clinic_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_payment_viewmodel.dart';
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
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/clinic_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/review_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/booking_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_list_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_appointment_detail_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/admin_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/chatbot_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/admin/admin_login_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/main_screen.dart';
import 'views/doctor/doctor_main_screen.dart';
import 'Constants/ui_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => AdminPaymentViewModel()),
        ChangeNotifierProvider(create: (_) => AdminClinicViewModel()),
        // --- ViewModel của chatbotAI ---
        ChangeNotifierProvider(create: (_) => ChatbotViewModel()),
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
        home: const SplashScreen(),
      ),
    );
  }
}

// CLASS SPLASH SCREEN ĐIỀU HƯỚNG TỰ ĐỘNG
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  // --- HÀM KIỂM TRA HẠN SỬ DỤNG CỦA TOKEN (JWT) ---
  bool _isTokenExpired(String? token) {
    
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true; // Token không hợp lệ

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] is int
            ? payloadMap['exp']
            : int.parse(payloadMap['exp'].toString());
        // Chuyển exp thành DateTime (x1000 vì exp tính bằng giây)
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        // Trả về true nếu thời gian hiện tại đã vượt qua thời gian hết hạn
        return DateTime.now().isAfter(expirationDate);
      }
      return false; // Nếu không có trường exp, mặc định cho qua (hoặc tùy logic)
    } catch (e) {
      return true; // Nếu có lỗi giải mã, coi như token hỏng/hết hạn
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    // Chờ 1.5 giây tạo hiệu ứng mượt mà
    await Provider.of<AuthViewModel>(context, listen: false).verifyToken();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Kiểm tra Admin Token
    final adminToken = prefs.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) {
      if (!_isTokenExpired(adminToken)) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        return;
      } else {
        // Token hết hạn -> Xóa token cũ
        await prefs.remove('admin_token');
      }
    }

    // 2. Kiểm tra phiên đăng nhập cũ của Bác sĩ / Bệnh nhân
    final userToken = prefs.getString('token');
    final role = prefs.getString('role'); // Đọc quyền từ cục bộ

    if (userToken != null && userToken.isNotEmpty) {
      if (!_isTokenExpired(userToken)) {
        if (role == 'Bac_si') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorMainScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        }
        return;
      } else {
        // Token hết hạn -> Xóa trắng dữ liệu đăng nhập
        await prefs.remove('token');
        await prefs.remove('role');
        await prefs.remove('ma_nguoi_dung');
      }
    }

    // 3. Nếu chưa đăng nhập hoặc token đã chết -> Đá về trang Login
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, size: 100, color: kPrimaryColor),
            SizedBox(height: 24),
            CircularProgressIndicator(color: kPrimaryColor),
          ],
        ),
      ),
    );
  }
}