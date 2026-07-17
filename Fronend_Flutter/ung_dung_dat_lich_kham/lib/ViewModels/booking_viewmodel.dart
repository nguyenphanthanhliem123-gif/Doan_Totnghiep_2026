import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class BookingViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _availableDates = [];
  List<String> get availableDates => _availableDates;

  List<dynamic> _schedule = [];
  List<dynamic> get schedule => _schedule;

  final String _baseUrl = "$BASE_URL/api/bookings";

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

  // Hàm gọi API lấy lịch khám của bác sĩ theo ngày
  Future<void> fetchDoctorSchedule(String date, int doctorId) async {
    _isLoading = true;
    _schedule = [];
    notifyListeners();

    try {
      // Ép kiểu URL chuẩn nhất, đảm bảo truyền đúng doctorId và date
      final url = Uri.parse('$_baseUrl/doctor-schedule?doctorId=$doctorId&date=$date');

      final response = await http.get(url);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        _schedule = responseData['schedule'] ?? [];
      } else {
        _schedule = [];
      }
    } catch (e) {
      print("Lỗi tải lịch bác sĩ: $e");
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
    required List<int> serviceIds, // ĐỔI THÀNH MẢNG (LIST)
    required int slotId,
    required String type,
    required String symptoms, 
    required String paymentMethod,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("Lỗi: Không tìm thấy token đăng nhập");
        return {"succeeded": false, "message": "Phiên đăng nhập hết hạn!"};
      }

      final url = Uri.parse(_baseUrl);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "Ma_bac_si": doctorId,
          "Ma_benh_nhan": patientId,
          "Ma_nguoi_than": relativeId,
          "Ma_dich_vu": serviceIds, // GỬI MẢNG LÊN BACKEND
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

  Future<Map<String, dynamic>> createVnpayPayment({
    required String bookingCode, 
  }) async {
    try {

      // 2. Gửi request gọi API Backend Node.js
      final response = await http.post(
        Uri.parse('$BASE_URL/api/payment/create-vnpay-url'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "bookingId": bookingCode,
        }),
      );

      // 3. Xử lý kết quả Backend trả về
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['succeeded'] == true) {
          // Trả về link thành công để BookingScreen mở URL
          return {
            "succeeded": true,
            "paymentUrl": body['data']['paymentUrl'],
          };
        } else {
          // Lỗi logic từ Backend (Dữ liệu sai, lỗi băm chuỗi bảo mật,...)
          return {
            "succeeded": false,
            "message": body['message'] ?? "Lỗi tạo giao dịch VNPay từ máy chủ.",
          };
        }
      } else {
        // Lỗi sập server hoặc sai URL (404, 500)
        return {
          "succeeded": false,
          "message": "Lỗi kết nối máy chủ (${response.statusCode}).",
        };
      }
    } catch (e) {
      // Lỗi mất mạng hoặc máy chủ không phản hồi
      print("Exception tại createVnpayPayment: $e");
      return {
        "succeeded": false,
        "message": "Mất kết nối mạng. Không thể khởi tạo cổng thanh toán.",
      };
    }
  }
  // Hàm Hủy lịch Online nếu bệnh nhân bấm nút Hủy ở cửa sổ VNPay
  Future<void> cancelUnpaidBooking(String bookingCode) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/cancel-unpaid'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"bookingCode": bookingCode}),
      );
    } catch (e) {
      print("Lỗi khi hủy lịch chưa thanh toán: $e");
    }
  }

  Future<String> checkPaymentStatus(String bookingCode) async {
    try {
      final url = Uri.parse('$_baseUrl/check-status/$bookingCode'); // Chỉnh lại theo đúng route API của bạn
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          return data['status']; // Trả về 'paid', 'pending', hoặc 'failed'
        }
      }
      else{
        final data = jsonDecode(response.body);
        print("Lỗi check trạng thái thanh toán: ${data['message']}");
      }
      return 'pending'; 
    } catch (e) {
      return 'pending';
    }
  }
}