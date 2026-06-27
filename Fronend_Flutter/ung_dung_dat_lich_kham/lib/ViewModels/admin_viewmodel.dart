import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // Đã thêm thư viện socket_io_client
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart'; 

class AdminViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Khai báo biến quản lý Socket.IO cho Admin
  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  // Các biến lưu trữ State Dashboard
  Map<String, dynamic> dashboardData = {
    'activeDoctors': 0,
    'totalPatients': 0,
    'pendingDoctors': 0,
    'openComplaints': 0,
    'todayAppointments': 0,
  };

  List<dynamic> pendingDoctors = [];

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

  // Lấy danh sách bác sĩ đang chờ duyệt
  Future<void> fetchPendingDoctors() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final response = await http.get(
        Uri.parse('$_baseUrl/pending-doctors'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        pendingDoctors = data['doctors'] ?? [];
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách bác sĩ chờ duyệt: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Duyệt hồ sơ bác sĩ
  Future<Map<String, dynamic>> approveDoctor(int maBacSi) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final response = await http.post(
        Uri.parse('$_baseUrl/approve-doctor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'maBacSi': maBacSi}),
      );

      debugPrint("🔥 LỖI TỪ BACKEND: ${response.body}");

      final data = jsonDecode(response.body);
      _setLoading(false);
      
      // Nếu thành công thì tải lại danh sách mới
      if (data['success'] == true) {
        await fetchPendingDoctors();
        fetchDashboardStats(); // Cập nhật lại số liệu trang chủ ngầm
      }
      return data;
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  // Từ chối hồ sơ bác sĩ (kèm lý do)
  Future<Map<String, dynamic>> rejectDoctor(int maBacSi, String reason) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final response = await http.post(
        Uri.parse('$_baseUrl/reject-doctor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'maBacSi': maBacSi, 'reason': reason}),
      );

      debugPrint("🔥 LỖI TỪ BACKEND: ${response.body}");

      final data = jsonDecode(response.body);
      _setLoading(false);

      if (data['success'] == true) {
        await fetchPendingDoctors();
        fetchDashboardStats(); 
      }
      return data;
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  @override
  void dispose() {
    disconnectSocket(); // Dọn dẹp kết nối socket khi đóng đối tượng ViewModel
    super.dispose();
  }
}