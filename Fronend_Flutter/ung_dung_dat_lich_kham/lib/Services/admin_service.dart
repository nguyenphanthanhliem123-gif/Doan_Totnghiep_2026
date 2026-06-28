import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';
import '../Models/user_model.dart';

class AdminService {
  // Hàm phụ trợ lấy token của Admin
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token'); // Nhớ dùng đúng key lưu token admin của bạn
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Lấy danh sách người dùng
  Future<List<UserModel>?> fetchAllUsers() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$BASE_URL/api/admin/users'), headers: headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['users'] != null) {
          List<dynamic> usersJson = data['users'];
          return usersJson.map((json) => UserModel.fromJson(json)).toList();
        }
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách user: $e');
    }
  }

  // 2. Khóa tài khoản
  Future<bool> lockAccount(int targetId, String reason) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "action": "LOCK_ACCOUNT",
        "target_type": "USER",
        "target_id": targetId,
        "reason": reason
      });

      final res = await http.post(
        Uri.parse('$BASE_URL/api/admin/lock-account'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 3. Mở khóa tài khoản
  Future<bool> unlockAccount(int targetId, String reason) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "action": "UNLOCK_ACCOUNT",
        "target_type": "USER",
        "target_id": targetId,
        "reason": reason
      });

      final res = await http.post(
        Uri.parse('$BASE_URL/api/admin/unlock-account'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}