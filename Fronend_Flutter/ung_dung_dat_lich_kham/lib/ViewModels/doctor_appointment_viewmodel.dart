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

  List<dynamic> pendingAppointments = [];
  List<dynamic> todayAppointments = [];

  final String _baseUrl = "$BASE_URL/api/appointments";

  // 1. Hàm gọi API lấy dữ liệu Trang chủ
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners(); // Báo cho UI hiện vòng quay loading

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final url = Uri.parse('$_baseUrl/doctor/dashboard');
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
          final payload = data['data'];
          // Gán dữ liệu vào biến
          pendingCount = payload['stats']['pendingCount'];
          todayCount = payload['stats']['todayCount'];
          cancelledCount = payload['stats']['cancelledCount'];
          pendingAppointments = payload['pendingAppointments'];
          todayAppointments = payload['todayAppointments'];
        }
      }
    } catch (e) {
      print("Lỗi load dashboard bác sĩ: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Báo cho UI update giao diện
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
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"action": action}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        // 🌟 Nếu cập nhật thành công, gọi lại hàm loadDashboard để làm mới màn hình ngay lập tức!
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
}