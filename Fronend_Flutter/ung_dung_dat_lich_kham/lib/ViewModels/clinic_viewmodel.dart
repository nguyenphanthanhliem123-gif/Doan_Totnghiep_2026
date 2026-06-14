import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/clinic_model.dart';

class ClinicViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ClinicModel? _clinicDetail;
  ClinicModel? get clinicDetail => _clinicDetail;

  final String _baseUrl = "http://localhost:3001/api/clinics";

  // Hàm gọi API lấy chi tiết phòng khám theo ID
  Future<void> fetchClinicDetail(int clinicId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/$clinicId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['succeeded'] == true) {
          _clinicDetail = ClinicModel.fromJson(responseData['data']);
        }
      } else {
        print("Lỗi từ server: Mã ${response.statusCode}");
      }
    } catch (error) {
      print("Lỗi kết nối API: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}