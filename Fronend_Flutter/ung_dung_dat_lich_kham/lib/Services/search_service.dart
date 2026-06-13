import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Config/BASE_URL.dart';

class APISearchService {
  Future<Map<String, dynamic>> searchGlobal(String keyword) async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/api/search/global-search?q=$keyword'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['succeeded'] == true) {
          return body['data']; // Trả về Map chứa doctors, specialties, clinics
        }
      }
      return {'doctors': [], 'specialties': [], 'clinics': []};
    } catch (e) {
      throw Exception('Lỗi tìm kiếm: $e');
    }
  }
}