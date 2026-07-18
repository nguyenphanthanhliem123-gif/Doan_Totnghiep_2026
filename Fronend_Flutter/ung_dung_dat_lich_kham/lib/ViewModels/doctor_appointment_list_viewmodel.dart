import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class DoctorAppointmentListViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _appointments = [];
  List<dynamic> get appointments => _appointments; // Chỉ cần 1 list duy nhất

  final String _baseUrl = "$BASE_URL/api/appointments";

  // Gọi API lấy danh sách kèm tham số Lọc
  Future<void> loadAllAppointments({String status = 'all', String date = 'all', String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      // Nối Query Params
      final url = Uri.parse('$_baseUrl/doctor/all-list?status=$status&date=$date&search=$search');
      
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          _appointments = data['data'];
        }
      }
    } catch (e) {
      print("Lỗi tải danh sách lịch hẹn của bác sĩ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật trạng thái thông thường (Ví dụ: Tiếp nhận, Đang khám, Hủy...)
  Future<Map<String, dynamic>> updateStatus(int appointmentId, String action, {String status = 'all', String date = 'all'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$_baseUrl/doctor/status/$appointmentId');
      final response = await http.put(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"action": action}));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        await loadAllAppointments(status: status, date: date); // Load lại đúng bộ lọc hiện tại
        return {"success": true, "message": data['message']};
      }
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }

  // Cập nhật trạng thái Bệnh nhân vắng mặt
  Future<Map<String, dynamic>> updateStatusAbsent(int appointmentId, {String status = 'all', String date = 'all'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$_baseUrl/doctor/status/absent/$appointmentId');
      final response = await http.put(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        await loadAllAppointments(status: status, date: date);
        return {"success": true, "message": data['message']};
      }
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }
}