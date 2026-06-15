import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _availableDates = [];
  List<String> get availableDates => _availableDates;

  final String _baseUrl = "http://localhost:3001/api/bookings";

  // Hàm gọi API lấy danh sách các ngày còn slot trống của bác sĩ
  Future<void> fetchAvailableDates(int doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/available-dates/$doctorId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['succeeded'] == true) {
          _availableDates = List<String>.from(responseData['data']);
        }
      }
    } catch (e) {
      print("Lỗi tải danh sách ngày trống: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm gọi API để gửi yêu cầu đặt lịch khám
  Future<Map<String, dynamic>> submitBooking({
    required int doctorId,
    required int patientId,
    int? relativeId,
    required int serviceId,
    required int slotId,
    required String type,
    required String symptoms, required String paymentMethod,
  }) async {
    try {
      final url = Uri.parse(_baseUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Ma_bac_si": doctorId,
          "Ma_benh_nhan": patientId,
          "Ma_nguoi_than": relativeId,
          "Ma_dich_vu": serviceId,
          "Ma_khung_gio": slotId,
          "Hinh_thuc": type,
          "Trieu_chung": symptoms,
          "Phuong_thuc": paymentMethod,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"succeeded": false, "message": "Lỗi kết nối Server: $e"};
    }
  }

  
}