import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/serviceModel.dart';
import 'package:ung_dung_dat_lich_kham/Services/medical_service.dart'; // Import file vừa tạo ở trên

class DoctorServiceViewModel extends ChangeNotifier {
  final APIMedicalService _apiService = APIMedicalService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MyServiceModel> myServices = [];
  List<ServiceModel> availableMasterServices = [];

  // Hàm xử lý Thêm
  Future<bool> addService(String name, int specId, double price) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _apiService.createService(serviceName: name, specId: specId, price: price);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xử lý Sửa
  Future<bool> editService(int id, {String? name, int? specId, double? price}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _apiService.updateService(serviceId: id, serviceName: name, specId: specId, price: price);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy các dịch vụ hiện tại bác sĩ đang chọn khám
  Future<void> fetchMyServices(int doctorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await http.get(
        Uri.parse('$BASE_URL/api/services/doctor/my-services/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List<dynamic> listService = data['data'];
          myServices = listService.map((json) => MyServiceModel.fromJson(json)).toList();
        }
      } else {
        // BỔ SUNG PRINT LỖI
        final data = jsonDecode(res.body);
        print('Lỗi fetchMyServices: ${data['message']}');
      }
    } catch (e) {
      debugPrint("Error fetchMyServices: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách dịch vụ mẫu của chuyên khoa để chuẩn bị chọn thêm
  Future<void> fetchAvailableMaster(int specId, int doctorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await http.get(
        Uri.parse('$BASE_URL/api/services/doctor/available-master?specId=$specId&doctorId=$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List<dynamic> listData = data['services'];
          availableMasterServices = listData.map((item) => ServiceModel.fromJson(item)).toList();
        }
      } else {
        // CẬP NHẬT PRINT LỖI RÕ RÀNG HƠN
        final data = jsonDecode(res.body);
        print('Lỗi fetchAvailableMaster: ${data['message']}');
      }
    } catch (e) {
      print("Error fetchAvailableMaster: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // Chọn thêm dịch vụ mới kèm giá tùy chỉnh
  Future<bool> chooseService(int doctorId, int masterServiceId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await http.post(
        Uri.parse('$BASE_URL/api/services/doctor/choose-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctorId': doctorId,
          'masterServiceId': masterServiceId,
        }),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      } else {
        // BỔ SUNG PRINT LỖI
        final data = jsonDecode(res.body);
        print('Lỗi chooseService: ${data['message']}');
      }
    } catch (e) {
      debugPrint("Error chooseService: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Xóa gỡ dịch vụ
  Future<bool> removeService(int serviceId, int doctorId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await http.post(
        Uri.parse('$BASE_URL/api/services/doctor/remove-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceId': serviceId, 
          'doctorId': doctorId
        }),
      );
      
      if (res.statusCode == 200) {
        return true;
      } else {
        // BỔ SUNG PRINT LỖI
        final data = jsonDecode(res.body);
        print('Lỗi removeService: ${data['message']}');
      }
    } catch (e) {
      debugPrint("Error removeService: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}