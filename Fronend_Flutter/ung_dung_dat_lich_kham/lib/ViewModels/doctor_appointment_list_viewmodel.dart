import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class DoctorAppointmentListViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _allAppointments = [];

  final String _baseUrl = "$BASE_URL/api/appointments";

  // --- Tự động tách danh sách thành 5 nhóm trạng thái dựa trên dữ liệu thật ---
  List<dynamic> get pendingList =>
      _allAppointments.where((e) => e['Trang_thai_lich_hen'] == 'pending').toList();

  List<dynamic> get confirmedList =>
      _allAppointments.where((e) => e['Trang_thai_lich_hen'] == 'confirmed').toList();

  List<dynamic> get doneList =>
      _allAppointments.where((e) => e['Trang_thai_lich_hen'] == 'done').toList();

  List<dynamic> get cancelledList =>
      _allAppointments.where((e) => e['Trang_thai_lich_hen'] == 'cancelled').toList();

  List<dynamic> get absentList =>
      _allAppointments.where((e) => e['Trang_thai_lich_hen'] == 'absent').toList();

  // Gọi API lấy toàn bộ danh sách lịch hẹn của Bác sĩ
  Future<void> loadAllAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final url = Uri.parse('$_baseUrl/doctor/all-list');
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
          _allAppointments = data['data'];
        }
      }
    } catch (e) {
      print("Lỗi tải toàn bộ danh sách lịch hẹn của bác sĩ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xử lý nhanh thao tác Duyệt / Từ chối trực tiếp tại danh sách
  Future<Map<String, dynamic>> updateStatus(int appointmentId, String action) async {
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
        await loadAllAppointments(); // Tải lại danh sách để cập nhật Tabs ngay lập tức
        return {"success": true, "message": data['message']};
      }
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }

  // Hàm xử lý Báo bệnh nhân vắng mặt công nghệ cao
  Future<Map<String, dynamic>> updateStatusAbsent(int appointmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$_baseUrl/doctor/status/absent/$appointmentId');
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        await loadAllAppointments(); // Làm mới toàn bộ 5 Tabs ngay lập tức
        return {"success": true, "message": data['message']};
      }
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }
}