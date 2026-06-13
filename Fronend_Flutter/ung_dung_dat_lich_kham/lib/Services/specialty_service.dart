import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Models/specialtyModel.dart';
import '../Config/BASE_URL.dart';
import '../Models/specialtyModel.dart';

class APISpecialtyService {
  Future<List<SpecialtyModel>?> getAllSpecialties() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/api/specialty/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['succeeded'] == true) {
          final List<dynamic> listJson = data['specialties'];
          return listJson.map((json) => SpecialtyModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi kết nối danh sách chuyên khoa: $e');
    }
  }
}