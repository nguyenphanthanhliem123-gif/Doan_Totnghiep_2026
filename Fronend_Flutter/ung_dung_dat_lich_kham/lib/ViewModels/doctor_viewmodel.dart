import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ung_dung_dat_lich_kham/Models/doctor_model.dart';
import 'package:ung_dung_dat_lich_kham/Services/doctor_service.dart';
import 'dart:convert';

import '../models/doctor_detail_model.dart'; 

class DoctorViewModel extends ChangeNotifier {

  final APIDoctorService _apiService = APIDoctorService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DoctorDetailModel? _doctorDetail;
  DoctorDetailModel? get doctorDetail => _doctorDetail;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<DoctorModel>? _listDoctor;
  List<DoctorModel>? get listDoctor => _listDoctor;

  String? _selectedDate;
  String? get selectedDate => _selectedDate;

  DoctorTimeSlotModel? _selectedSlot;
  DoctorTimeSlotModel? get selectedSlot => _selectedSlot;

  // Cấu hình URL gọi tới API lấy chi tiết bác sĩ
  final String _baseUrl = "http://localhost:3001/api/doctors";

  Future<void> loadDoctors({
    int? specialtyId, String? location, double? minPrice, 
    double? maxPrice, double? minRating, String? availableDate
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _listDoctor = await _apiService.getDoctors(
        specialtyId: specialtyId, location: location, minPrice: minPrice, 
        maxPrice: maxPrice, minRating: minRating, availableDate: availableDate
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm gọi API để lấy chi tiết bác sĩ theo ID
  Future<void> fetchDoctorDetail(int doctorId) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      final url = Uri.parse('$_baseUrl/$doctorId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['succeeded'] == true) {
          // Ép kiểu JSON từ Backend trả về vào trong Model của Flutter
          _doctorDetail = DoctorDetailModel.fromJson(responseData['data']);
          
          // Tự động chọn ngày đầu tiên (nếu có lịch) để UI không bị trống
          if (_doctorDetail!.schedules.isNotEmpty) {
            _selectedDate = _doctorDetail!.schedules.first.date;
          }
        }
      } else {
        print("Lỗi từ server: Mã ${response.statusCode}");
      }
    } catch (error) {
      print("Lỗi kết nối API: $error");
    } finally {
      // Dù thành công hay thất bại cũng phải tắt vòng xoay loading
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm xử lý khi người dùng chọn một ngày khác trên thanh cuộn ngang
  void selectDate(String date) {
    _selectedDate = date;
    _selectedSlot = null; // Phải reset lại giờ đã chọn nếu người dùng chuyển sang ngày khác
    notifyListeners();
  }

  // Hàm xử lý khi người dùng bấm chọn một khung giờ
  void selectSlot(DoctorTimeSlotModel slot) {
    if (slot.status == 'available') { // Chỉ cho phép chọn nếu khung giờ này còn trống
      _selectedSlot = slot;
      notifyListeners();
    }
  }

}

