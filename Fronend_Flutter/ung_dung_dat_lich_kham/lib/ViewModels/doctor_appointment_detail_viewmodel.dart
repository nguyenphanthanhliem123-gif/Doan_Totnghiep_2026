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

  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;

  List<dynamic> _medicalHistory = [];
  List<dynamic> get medicalHistory => _medicalHistory;

  bool _isPrescriptionLoading = false;
  bool get isPrescriptionLoading => _isPrescriptionLoading;

  Map<String, dynamic>? _prescriptionData;
  Map<String, dynamic>? get prescriptionData => _prescriptionData;

  // Gọi API lấy lịch sử bệnh án (các ca khám cũ)
  Future<void> fetchMedicalHistory(int appointmentId) async {
    _isHistoryLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final url = Uri.parse('$_baseUrl/doctor/medical-history/$appointmentId');
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
          _medicalHistory = data['data'];
        }
      }
    } catch (e) {
      print("Lỗi tải lịch sử bệnh án: $e");
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

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

  // Hàm gửi đơn thuốc và hoàn thành ca khám
  Future<Map<String, dynamic>> completeAndPrescribe(int appointmentId, String chuanDoan, String? ngayTaiKham, List<Map<String, dynamic>> danhSachThuoc) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('$_baseUrl/doctor/prescribe/$appointmentId');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "chuanDoan": chuanDoan,
          "ngayTaiKham": ngayTaiKham, // Có thể null
          "danhSachThuoc": danhSachThuoc
        })
      );

      final data = jsonDecode(response.body);
      return {"success": data['succeeded'] == true, "message": data['message'] ?? "Lỗi không xác định"};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối Server"};
    } finally {
      // Dù thành công hay thất bại cũng gọi lại hàm lấy chi tiết để cập nhật giao diện
      await fetchAppointmentDetail(appointmentId); 
    }
  }

  // Hàm xem đơn thuốc
  Future<void> fetchPrescription(int appointmentId) async {
    _isPrescriptionLoading = true;
    _prescriptionData = null; // Reset data cũ
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final url = Uri.parse('$_baseUrl/doctor/prescription/$appointmentId');
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          _prescriptionData = data['data'];
        }
      }
    } catch (e) {
      print("Lỗi tải đơn thuốc: $e");
    } finally {
      _isPrescriptionLoading = false;
      notifyListeners();
    }
  }

  // 1. Cập nhật trạng thái thông thường (Ví dụ: Tiếp nhận, Đang khám, Hủy...)
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
          "Authorization": "Bearer $token"
        }, 
        body: jsonEncode({"action": action})
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['succeeded'] == true) {
        // Tự động kéo lại chi tiết mới nhất của ca khám để UI cập nhật ngay lập tức
        await fetchAppointmentDetail(appointmentId);
        return {"success": true, "message": data['message']};
      }
      
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }

  // 2. Cập nhật trạng thái Bệnh nhân vắng mặt
  Future<Map<String, dynamic>> updateStatusAbsent(int appointmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('$_baseUrl/doctor/status/absent/$appointmentId');

      final response = await http.put(
        url, 
        headers: {
          "Content-Type": "application/json", 
          "Authorization": "Bearer $token"
        }
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['succeeded'] == true) {
        // Tự động kéo lại chi tiết mới để UI cập nhật nút bấm hoặc nhãn trạng thái
        await fetchAppointmentDetail(appointmentId);
        return {"success": true, "message": data['message']};
      }
      
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": data['message'] ?? "Thao tác thất bại"};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối Server"};
    }
  }
}