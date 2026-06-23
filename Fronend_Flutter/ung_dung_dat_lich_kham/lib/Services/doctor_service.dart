import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/doctor_model.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');
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
      final res = await http.get(
        uri,
      );
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

  // Hàm gọi API /api/doctors/update
  Future<bool> updateDoctorProfile({
    String? hocVi,
    String? soNamKinhNghiem,
    int? maChuyenKhoa,
    String? moTaBanThan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/api/doctors/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        // Chú ý: Các key này phải khớp chính xác với req.body bên doctorController.js
        body: jsonEncode({
          "hoc_vi": hocVi,
          "so_nam_kinh_nghiem": soNamKinhNghiem,
          "ma_chuyen_khoa": maChuyenKhoa,
          "mo_ta": moTaBanThan,
        }),
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(res.body);
        print("Lỗi Backend Update Doctor: ${data['message']}");
        throw Exception(data['message'] ?? "Cập nhật hồ sơ thất bại");
      }
    } catch (e) {
      print("Lỗi APIDoctorService: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<DoctorModel?> fetchDoctorDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/doctors/detail'),
        headers: {'Authorization': 'Bearer $token',}
      );

      final data = jsonDecode(res.body);

      if(res.statusCode == 200){
        return DoctorModel.fromJson(data['data']);
      }
      else{
        print('Lỗi: ${data['message']}');
        return null;
      }
    }catch(e){
      throw Exception("Lỗi server: ${e.toString()}");
    }
  }

  // Hàm lấy thông tin phòng khám đã chọn
  Future<Map<String, int?>?> getMySelectedClinics() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/api/doctors/my-clinics'),
        headers: {'Authorization': 'Bearer $token'}
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['succeeded'] == true) {
          return {
            'currentClinicId': body['data']['currentClinicId'],
            'primaryClinicId': body['data']['primaryClinicId'],
          };
        }
      }
      return null;
    } catch (e) {
      print("Lỗi getMySelectedClinics: $e");
      return null;
    }
  }
}