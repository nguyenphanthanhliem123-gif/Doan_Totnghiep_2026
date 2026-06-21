import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';
import '../Models/doctor_model.dart';

class APIDoctorService {
  // Lấy danh sách bác sĩ (có hỗ trợ lọc theo chuyên khoa)
  Future<List<DoctorModel>?> getDoctors({
    int? specialtyId,
    String? location,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? availableDate,
    String? sortBy,
    double? userLat,
    double? userLng,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (specialtyId != null) queryParams['specialtyId'] = specialtyId.toString();
      if (location != null && location.isNotEmpty) queryParams['location'] = location;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (availableDate != null) queryParams['availableDate'] = availableDate;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (userLat != null) queryParams['userLat'] = userLat.toString();
      if (userLng != null) queryParams['userLng'] = userLng.toString();

      final uri = Uri.parse('$BASE_URL/api/doctors').replace(queryParameters: queryParams);
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (data['succeeded'] == true) {
          final List<dynamic> listJson = data['doctors'];
          return listJson.map((json) => DoctorModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Lỗi không xác định từ server');
        }
      } else {
        // 🛑 THROW LỖI: Giúp ViewModel bắt được thông tin lỗi cụ thể thay vì âm thầm trả về []
        throw Exception(data['message'] ?? 'Lỗi kết nối Server với mã phản hồi: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Hệ thống gặp sự cố: $e');
    }
  }
}