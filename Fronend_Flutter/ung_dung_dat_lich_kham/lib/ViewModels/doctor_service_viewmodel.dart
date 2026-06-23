import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Services/medical_service.dart'; // Import file vừa tạo ở trên

class DoctorServiceViewModel extends ChangeNotifier {
  final APIMedicalService _apiService = APIMedicalService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  // Hàm xử lý Xóa
  Future<bool> removeService(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _apiService.deleteService(id);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}