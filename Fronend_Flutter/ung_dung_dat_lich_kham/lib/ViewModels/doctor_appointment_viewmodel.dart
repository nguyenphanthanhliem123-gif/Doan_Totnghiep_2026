import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class DoctorAppointmentViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int pendingCount = 0;
  int todayCount = 0;
  int cancelledCount = 0;
  double todayRevenue = 0;
  List<dynamic> revenueDetails = [];

  // 🌟 Biến quản lý trạng thái hoạt động của bác sĩ
  bool isDoctorActive = true; 

  List<dynamic> pendingAppointments = [];
  List<dynamic> todayAppointments = [];

  final String _baseUrl = "$BASE_URL/api/appointments";

  // 1. Hàm gọi API lấy dữ liệu Trang chủ
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      // Kéo dữ liệu Dashboard
      final url = Uri.parse('$_baseUrl/doctor/dashboard');
      final response = await http.get(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});

      // Kéo trạng thái Rảnh/Bận
      final statusUrl = Uri.parse('$_baseUrl/doctor/active-status');
      final statusResponse = await http.get(statusUrl, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          final payload = data['data'];
          pendingCount = payload['stats']['pendingCount'];
          todayCount = payload['stats']['todayCount'];
          cancelledCount = payload['stats']['cancelledCount'];
          todayRevenue = double.tryParse(payload['stats']['todayRevenue'].toString()) ?? 0; 
          revenueDetails = payload['revenueDetails'] ?? [];
          pendingAppointments = payload['pendingAppointments'];
          todayAppointments = payload['todayAppointments'];
        }
      }

      if (statusResponse.statusCode == 200) {
        final stData = jsonDecode(statusResponse.body);
        if (stData['succeeded'] == true) {
          isDoctorActive = stData['data']['status'] == 'active';
        }
      }

    } catch (e) {
      print("Lỗi load dashboard bác sĩ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Hàm gọi API Xác nhận / Từ chối lịch hẹn
  Future<Map<String, dynamic>> updateStatus(int appointmentId, String action) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$_baseUrl/doctor/status/$appointmentId');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"action": action}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        await loadDashboard();
        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": data['message'] ?? "Lỗi cập nhật"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối server"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Hàm Bật/Tắt trạng thái hoạt động
  Future<Map<String, dynamic>> toggleActiveStatus(bool value) async {
    // Optimistic UI Update: Đổi trạng thái trên màn hình ngay lập tức cho mượt
    final oldStatus = isDoctorActive;
    isDoctorActive = value;
    notifyListeners(); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$_baseUrl/doctor/active-status');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"status": value ? 'active' : 'suspended'})
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        return {"success": true, "message": data['message']};
      } else {
        // Nếu API lỗi, revert lại trạng thái cũ
        isDoctorActive = oldStatus;
        notifyListeners();
        return {"success": false, "message": data['message'] ?? "Lỗi cập nhật trạng thái"};
      }
    } catch (e) {
      isDoctorActive = oldStatus; // Revert
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối server"};
    }
  }
}