import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class DoctorAppointmentDetailViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _appointmentDetail;
  Map<String, dynamic>? get appointmentDetail => _appointmentDetail;

  final String _baseUrl = "$BASE_URL/api/appointments";

  // Gọi API lấy chi tiết 1 ca khám cụ thể
  Future<void> fetchAppointmentDetail(int appointmentId) async {
    _isLoading = true;
    _appointmentDetail = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final url = Uri.parse('$_baseUrl/doctor/detail/$appointmentId');
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
          _appointmentDetail = data['data'];
        }
      }
    } catch (e) {
      print("Lỗi tải chi tiết ca khám bác sĩ: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}