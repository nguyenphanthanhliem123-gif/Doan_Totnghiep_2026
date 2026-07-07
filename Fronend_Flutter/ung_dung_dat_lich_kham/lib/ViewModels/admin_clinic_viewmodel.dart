import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';
import '../models/clinic_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminClinicViewModel extends ChangeNotifier {
  List<ClinicModel> _clinics = [];
  bool _isLoading = false;

  List<ClinicModel> get clinics => _clinics;
  bool get isLoading => _isLoading;

  Future<void> fetchClinics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? ''; // Thay bằng key token admin của bạn

      final response = await http.get(
        Uri.parse('$BASE_URL/api/admin/clinics'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          _clinics = (data['clinics'] as List).map((e) => ClinicModel.fromJson(e)).toList();
        }
      }
      else{
        final data = json.decode(response.body);
        print("Lỗi fetchClinics: ${data['message']}");
      }
    } catch (e) {
      print("Lỗi fetchClinics: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveClinic({int? id, required Map<String, dynamic> data}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';
      
      final url = id == null 
          ? '$BASE_URL/api/admin/clinics' 
          : '$BASE_URL/api/admin/clinics/$id';
          
      final response = await (id == null ? http.post : http.put)(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchClinics();
        return true;
      }
      else{
        final data = json.decode(response.body);
        print("Lỗi fetchClinics: ${data['message']}");
      }
    } catch (e) {
      print("Lỗi saveClinic: $e");
    }
    return false;
  }

  // Hàm tải ảnh phòng khám lên Server
  Future<bool> uploadClinicImage(int clinicId, XFile imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/api/admin/clinics/$clinicId/images'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // 🌟 ĐỌC FILE DƯỚI DẠNG BYTE ĐỂ HỖ TRỢ CẢ WEB VÀ MOBILE
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', 
          bytes,
          filename: imageFile.name, // Đính kèm tên file
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      }else{
        final data = json.decode(response.body);
        print("Lỗi fetchClinics: ${data['message']}");
      }
    } catch (e) {
      print("Lỗi tải ảnh lên: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}