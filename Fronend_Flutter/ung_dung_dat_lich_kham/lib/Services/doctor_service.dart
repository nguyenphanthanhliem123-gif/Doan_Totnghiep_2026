import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';
import '../Models/doctor_model.dart';

class APIDoctorService {
  // Lấy danh sách bác sĩ (có hỗ trợ lọc theo chuyên khoa)
  Future<List<DoctorModel>?> getDoctors({int? specialtyId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Xây dựng URL có param nếu specialtyId được truyền vào
      String url = '$BASE_URL/api/doctors/';
      if (specialtyId != null) {
        url += '?specialtyId=$specialtyId';
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['succeeded'] == true) {
          final List<dynamic> listJson = data['doctors'];
          return listJson.map((json) => DoctorModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải danh sách bác sĩ: $e');
    }
  }
}