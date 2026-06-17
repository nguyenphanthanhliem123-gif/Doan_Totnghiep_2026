import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';

class AppointmentViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> get allAppointments => _allAppointments;

  // Cấu hình URL đồng bộ với booking_viewmodel
  final String _baseUrl = "http://localhost:3001/api/appointments";

  // Tự động lọc danh sách cho 3 Tab 
  List<AppointmentModel> get upcomingList => _allAppointments
      .where((e) => e.status == 'pending' || e.status == 'confirmed')
      .toList();

  List<AppointmentModel> get completedList => _allAppointments
      .where((e) => e.status == 'done')
      .toList();

  List<AppointmentModel> get cancelledList => _allAppointments
      .where((e) => e.status == 'cancelled' || e.status == 'absent')
      .toList();

  // Hàm gọi API lấy danh sách lịch hẹn 
  Future<void> loadMyAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Lấy token để truyền qua Middleware (auth.js)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("Lỗi: Không tìm thấy token đăng nhập");
        return;
      }

      final url = Uri.parse('$_baseUrl/my-list');
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
        print("Lỗi từ server: ${response.body}");
      }
    } catch (e) {
      print("Lỗi tải danh sách lịch hẹn: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}