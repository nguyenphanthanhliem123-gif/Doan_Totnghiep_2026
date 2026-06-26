import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart'; 

class AdminViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Endpoint Backend cho Admin (Sử dụng BASE_URL chung của dự án)
  final String _baseUrl = "$BASE_URL/api/admin";

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1. API Login Admin (Gửi Email & Pass)
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      _setLoading(false);
      return data; // Kết quả trả về: {success: bool, message: string}
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 2. API Verify OTP (Gửi Email & OTP -> Trả về JWT Token)
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', data['token']);
        await prefs.setBool('is_admin', true);
      }
      
      _setLoading(false);
      return data; // Kết quả trả về: {success: bool, token: string, message: string}
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Lỗi xác thực: $e'};
    }
  }

  // 3. Đăng xuất Admin
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('is_admin');
    notifyListeners();
  }
}