import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // Đã thêm thư viện socket_io_client
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/appointment_detail_model.dart';
import 'package:ung_dung_dat_lich_kham/Models/appointment_model.dart';
import 'package:ung_dung_dat_lich_kham/Models/user_model.dart';
import 'package:ung_dung_dat_lich_kham/Services/admin_service.dart'; 

class AdminViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Khai báo biến quản lý Socket.IO cho Admin
  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  List<UserModel>? _accountList = [];
  List<UserModel>? get accountList => _accountList;

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> get allAppointments => _allAppointments;

  // ✅ Thêm biến lưu dữ liệu Chi tiết lịch hẹn
  AppointmentDetailModel? _appointmentDetail;
  AppointmentDetailModel? get appointmentDetail => _appointmentDetail;



  // Các biến lưu trữ State Dashboard
  Map<String, dynamic> dashboardData = {
    'activeDoctors': 0,
    'totalPatients': 0,
    'pendingDoctors': 0,
    'openComplaints': 0,
    'todayAppointments': 0,
  };

  // Endpoint Backend cho Admin (Sử dụng BASE_URL chung của dự án)
  final String _baseUrl = "$BASE_URL/api/admin";

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =====================================================================
  // LUỒNG REAL-TIME: KẾT NỐI SOCKET.IO CHO QUẢN TRỊ VIÊN
  // =====================================================================
  
  // Hàm khởi tạo và cấu hình kết nối Socket.IO
  void initSocket() async {
    if (_socket != null && _socket!.connected) return; // Đã kết nối thì bỏ qua

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token'); // Lấy đúng admin_token của Admin
    if (token == null) return;

    _socket = IO.io(BASE_URL, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token}) // Đẩy token lên handshake auth ngầm giống User
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('✅ Admin Socket.IO đã kết nối real-time thành công!');
    });

    // 🌟 LẮNG NGHE SỰ KIỆN BIẾN ĐỘNG HỆ THỐNG TỪ BACKEND
    _socket!.on('admin_dashboard_update', (_) {
      debugPrint('🔄 Phát hiện hệ thống có thay đổi real-time! Đang cập nhật số liệu ngầm...');
      fetchDashboardStats(isRefresh: true); // Gọi hàm tải lại data ngầm, ko chớp màn hình
    });

    _socket!.onDisconnect((_) => debugPrint('❌ Mất kết nối Admin Socket.IO'));
  }

  // Hàm ngắt kết nối an toàn khi hủy luồng hoặc logout
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // =====================================================================
  // CÁC HÀM API CHỨC NĂNG CỦA ADMIN
  // =====================================================================

  // 1. API Login Admin (Gửi Email & Pass)
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      _setLoading(false);
      return data; 
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 2. API Verify OTP (Gửi Email & OTP -> Trả về JWT Token)
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', data['token']);
        await prefs.setBool('is_admin', true);
      }
      
      _setLoading(false);
      return data; 
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi xác thực: $e'};
    }
  }

  // 3. Đăng xuất Admin
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('is_admin');
    disconnectSocket(); // Ngắt kết nối socket real-time ngay khi logout
    notifyListeners();
  }

  // 4. Hàm gọi API Dashboard (Đã tối ưu hóa tránh chớp màn hình khi Real-time cập nhật)
  Future<void> fetchDashboardStats({bool isRefresh = false}) async {
    // Nếu là refresh ngầm từ Socket hoặc kéo màn hình, ta không set trạng thái Loading xoay vòng
    if (!isRefresh) _setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        dashboardData = data['data'];
        notifyListeners(); // Cập nhật lại UI khi số liệu thay đổi
      }
    } catch (e) {
      debugPrint("Lỗi tải Dashboard: $e");
    } finally {
      if (!isRefresh) _setLoading(false);
    }
  }

  // Lấy danh sách tài khoản từ API
  Future<void> fetchAccounts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _accountList = await _adminService.fetchAllUsers();
    } catch (e) {
      debugPrint("Lỗi tải danh sách: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm khóa tài khoản
  Future<bool> lockUserAccount({required int userId, required String reason}) async {
    final success = await _adminService.lockAccount(userId, reason);
    if (success) {
      // Cập nhật giao diện lập tức (giả sử status = 0 là khóa)
      final index = _accountList?.indexWhere((u) => u.id == userId);
      if (index != null && index != -1) {
        _accountList![index].status = 2; 
        notifyListeners();
      }
    }
    return success;
  }

  // Hàm mở khóa tài khoản
  Future<bool> unlockUserAccount({required int userId, String reason = "Mở khóa định kỳ"}) async {
    final success = await _adminService.unlockAccount(userId, reason);
    if (success) {
      // Cập nhật giao diện lập tức (giả sử status = 1 là hoạt động)
      final index = _accountList?.indexWhere((u) => u.id == userId);
      if (index != null && index != -1) {
        _accountList![index].status = 1;
        notifyListeners();
      }
    }
    return success;
  }

  // Hàm gọi API lấy danh sách lịch hẹn của bệnh nhân
  Future<void> loadAppointmentsByUserId(userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      if (token == null) {
        print("Lỗi: Không tìm thấy token đăng nhập");
        return;
      }

      final url = Uri.parse('$_baseUrl/user-appointment/$userId');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['succeeded'] == true) {
          final List<dynamic> listJson = responseData['data'];
          _allAppointments = listJson.map((json) => AppointmentModel.fromJson(json)).toList();
        } else {
          _allAppointments = [];
        }
      } else {
        final responseData = jsonDecode(response.body);
        print("Lỗi từ server: ${response.body}, ${responseData['message']}");
      }
    } catch (e) {
      print("Lỗi tải danh sách lịch hẹn: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm gọi API lấy chi tiết lịch hẹn dựa trên Ma_lich_hen (appointmentId)
  Future<void> fetchAppointmentDetail(int appointmentId) async {
    _isLoading = true;
    _errorMessage = '';
    _appointmentDetail = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      if (token == null) {
        _errorMessage = 'Vui lòng đăng nhập lại.';
        return;
      }

      final url = Uri.parse('$_baseUrl/user-appointment-detail/$appointmentId');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          _appointmentDetail = AppointmentDetailModel.fromJson(data['data']);
        } else {
          _errorMessage = data['message'] ?? 'Lỗi tải dữ liệu';
        }
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Lỗi kết nối máy chủ';
      }
    } catch (e) {
      _errorMessage = "Không thể tải chi tiết lịch hẹn: ${e.toString().replaceAll('Exception: ', '')}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnectSocket(); // Dọn dẹp kết nối socket khi đóng đối tượng ViewModel
    super.dispose();
  }
}