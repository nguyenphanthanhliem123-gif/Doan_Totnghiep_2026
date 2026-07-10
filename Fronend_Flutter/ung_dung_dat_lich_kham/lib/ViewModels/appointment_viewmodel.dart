import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Services/appointment_service.dart';
import '../models/appointment_model.dart';
import '../models/appointment_detail_model.dart';

class AppointmentViewModel extends ChangeNotifier {
  APIAppointmentService _apiAppointment = APIAppointmentService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = ''; // Thêm biến lưu lỗi để hiển thị lên UI
  String get errorMessage => _errorMessage;

  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> get allAppointments => _allAppointments;

  // ✅ Thêm biến lưu dữ liệu Chi tiết lịch hẹn
  AppointmentDetailModel? _appointmentDetail;
  AppointmentDetailModel? get appointmentDetail => _appointmentDetail;

  bool? _doneStatus;
  bool? get doneStatus => _doneStatus;

  bool _isPrescriptionLoading = false;
  bool get isPrescriptionLoading => _isPrescriptionLoading;

  Map<String, dynamic>? _prescriptionData;
  Map<String, dynamic>? get prescriptionData => _prescriptionData;

  // Cấu hình URL đồng bộ
  final String _baseUrl = "$BASE_URL/api/appointments";

  // --- Tự động lọc danh sách cho 3 Tab ---
  List<AppointmentModel> get upcomingList {
    return _allAppointments.where((e) {
      return e.status == 'pending' || e.status == 'confirmed';
    }).toList();
  }

  List<AppointmentModel> get completedList {
    return _allAppointments.where((e) {
      // Bác sĩ đã bấm hoàn thành thì mới được vào đây
      return e.status == 'done';
    }).toList();
  }

  List<AppointmentModel> get cancelledList {
    return _allAppointments.where((e) {
      // Đã bị hủy hoặc bác sĩ đánh dấu vắng mặt
      return e.status == 'cancelled' || e.status == 'absent';
    }).toList();
  }

  // Hàm gọi API lấy danh sách lịch hẹn của bệnh nhân
  Future<void> loadMyAppointments() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
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
  Future<void> fetchDetail(int appointmentId) async {
    _isLoading = true;
    _errorMessage = '';
    _appointmentDetail = null; // Reset dữ liệu cũ trước khi gọi data mới
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _errorMessage = 'Vui lòng đăng nhập lại.';
        return;
      }

      final url = Uri.parse('$_baseUrl/detail/$appointmentId');
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

  // Hàm gọi API hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {"succeeded": false, "message": "Vui lòng đăng nhập lại."};

      final url = Uri.parse('$_baseUrl/cancel/$appointmentId');
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        // Đồng bộ lại danh sách lịch hẹn chung ở màn hình ngoài (để tab tự cập nhật)
        await loadMyAppointments();
        return {"succeeded": true, "message": data['message']};
      } else {
        return {"succeeded": false, "message": data['message'] ?? "Hủy lịch không thành công."};
      }
    } catch (e) {
      return {"succeeded": false, "message": "Lỗi kết nối Server: $e"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm gọi API Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ
  Future<Map<String, dynamic>> rescheduleAppointment(int appointmentId, int newSlotId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {"succeeded": false, "message": "Vui lòng đăng nhập lại."};

      final url = Uri.parse('$_baseUrl/reschedule/$appointmentId');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"newSlotId": newSlotId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['succeeded'] == true) {
        await loadMyAppointments(); // Đồng bộ lại list
        return {"succeeded": true, "message": data['message']};
      } else {
        return {"succeeded": false, "message": data['message'] ?? "Đổi lịch thất bại."};
      }
    } catch (e) {
      return {"succeeded": false, "message": "Lỗi kết nối Server: $e"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDoneStatus(appointmentID) async {
    _isLoading = true;
    _errorMessage ='';
    notifyListeners();

    try {
      _doneStatus = await _apiAppointment.updateDoneStatusAppointment(appointmentID);
    } catch (e) {
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrescription(int appointmentId) async {
    _isPrescriptionLoading = true;
    _prescriptionData = null; 
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      // Gọi đúng Endpoint bảo mật mới của Bệnh nhân
      final url = Uri.parse('$_baseUrl/prescription/$appointmentId');
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          _prescriptionData = data['data'];
        }
      } else {
        // ✨ THÊM DÒNG NÀY ĐỂ DEBUG TRÊN TERMINAL
        print("🔥 LỖI TẢI ĐƠN THUỐC: HTTP ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Lỗi tải đơn thuốc phía Bệnh nhân: $e");
    } finally {
      _isPrescriptionLoading = false;
      notifyListeners();
    }
  }
}