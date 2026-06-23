import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class APIMedicalService {
  
  // 1. API THÊM DỊCH VỤ MỚI
  // Định dạng Route backend: POST /api/services/create
  Future<bool> createService({
    required String serviceName,
    required int specId,
    required double price,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

      final res = await http.post(
        Uri.parse('$BASE_URL/api/services/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'serviceName': serviceName,
          'specId': specId,
          'price': price,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['succeeded'] ?? false;
      } else {
        final data = jsonDecode(res.body);
        print('Lỗi thêm dịch vụ: ${data['message']}');
        return false;
      }
    } catch (e) {
      throw Exception('Lỗi kết nối server: ${e.toString()}');
    }
  }

  // 2. API CẬP NHẬT DỊCH VỤ
  // Định dạng Route backend: PUT /api/services/update/:serviceId
  // Các tham số truyền vào có dấu ? (có thể null) để đồng bộ với cơ chế dynamic SQL ở backend của bạn
  Future<bool> updateService({
    required int serviceId,
    String? serviceName,
    int? specId,
    double? price,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

      // Chỉ gửi lên Backend những trường dữ liệu thực sự thay đổi (không null)
      Map<String, dynamic> bodyData = {};
      if (serviceName != null) bodyData['serviceName'] = serviceName;
      if (specId != null) bodyData['specId'] = specId;
      if (price != null) bodyData['price'] = price;

      final res = await http.put(
        Uri.parse('$BASE_URL/api/services/update/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['succeeded'] ?? false;
      } else {
        final data = jsonDecode(res.body);
        print('Lỗi cập nhật dịch vụ: ${data['message']}');
        return false;
      }
    } catch (e) {
      throw Exception('Lỗi kết nối server: ${e.toString()}');
    }
  }

  // 3. API XÓA DỊCH VỤ
  // Định dạng Route backend: DELETE /api/services/delete/:serviceId
  Future<bool> deleteService(int serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

      final res = await http.delete(
        Uri.parse('$BASE_URL/api/services/delete/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['succeeded'] ?? false;
      } else {
        final data = jsonDecode(res.body);
        print('Lỗi xóa dịch vụ: ${data['message']}');
        return false;
      }
    } catch (e) {
      throw Exception('Lỗi kết nối server: ${e.toString()}');
    }
  }
}