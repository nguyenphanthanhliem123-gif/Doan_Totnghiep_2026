import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/health_record_model.dart';
import 'package:http/http.dart' as http;

class APIHealRecordService{
  Future<List<HealthRecordModel>?> getAllHealthRecordByUserID() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;

    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/record/'),
        headers: {
          'Authorization': 'Bearer $token'
        }
      );

      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        if(data['succeeded'] == true){
          final List<dynamic> recordJson = data['healthRecords'];
          return recordJson.map((json) => HealthRecordModel.fromJson(json)).toList();
        }
        else{
           return [];
        }
      }else{
        final data = jsonDecode(res.body);
        throw Exception('Lỗi lấy hồ dơ sức khỏe: ${data['message']}');
      }
    }
    catch(e){
      print('Lỗi fetch hồ sơ: $e');
      throw Exception('Không thể tải danh sách hồ sơ');
    }
  }

  // Hàm thêm hồ sơ người thân
  Future<bool> addRelativeRecord({
    required String tenNguoiThan,
    required String moiQuanHe,
    required DateTime birthDay,
    required int gender,
    required String address,
    String? nhomMau,
    String? diUng,
    String? benhNen,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/api/record/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "tenNguoiThan": tenNguoiThan,
          "moiQuanHe": moiQuanHe,
          // Format ngày sinh YYYY-MM-DD để tránh lỗi múi giờ
          "birthDay": "${birthDay.year}-${birthDay.month.toString().padLeft(2, '0')}-${birthDay.day.toString().padLeft(2, '0')}",
          "gender": gender,
          "address": address,
          "nhomMau": nhomMau,
          "diUng": diUng,
          "benhNen": benhNen
        }),
      );

      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['succeeded'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Thêm hồ sơ thất bại');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}