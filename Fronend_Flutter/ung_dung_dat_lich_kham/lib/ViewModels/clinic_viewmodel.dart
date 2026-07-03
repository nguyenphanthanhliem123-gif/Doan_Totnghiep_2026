import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Services/clinic_service.dart';
import 'dart:convert';
import 'package:ung_dung_dat_lich_kham/Models/clinic_model.dart';

class ClinicViewModel extends ChangeNotifier {
  APIClinicService _apiClinic = APIClinicService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ClinicModel? _clinicDetail;
  ClinicModel? get clinicDetail => _clinicDetail;

  List<ClinicModel>? _listClinic;
  List<ClinicModel>? get listClinic => _listClinic;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = "$BASE_URL/api/clinics";

  // Hàm gọi API lấy chi tiết phòng khám theo ID
  Future<void> fetchClinicDetail(int clinicId) async {
    _isLoading = true;
    _clinicDetail = null;
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

  Future<void> fetchAllClinic()async{
    _isLoading = true;
    _errorMessage = '';
    _listClinic = null;
    notifyListeners();

    try{
      _listClinic = await _apiClinic.fetchAllClinic();
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }
  }
}