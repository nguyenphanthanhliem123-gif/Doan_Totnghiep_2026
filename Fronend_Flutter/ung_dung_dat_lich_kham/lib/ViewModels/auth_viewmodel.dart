import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Điểm cấu hình URL của API Backend Node.js
  final String _baseUrl = "http://localhost:3001/api/auth";

  // Hàm kết nối API Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    // 1. Bật trạng thái Loading để giao diện hiển thị vòng xoay
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/login');

    try {
      // 2. Gửi request POST kèm theo body là JSON chứa thông tin tài khoản
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      // 3. Giải mã dữ liệu JSON trả về từ Node.js
      final responseData = jsonDecode(response.body);

      print("BACKEND TRA VE CUC NAY: $responseData");

      _isLoading = false;
      notifyListeners();

      // 4. Kiểm tra mã trạng thái HTTP trả về từ Backend (200 OK)
      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        final prefs = await SharedPreferences.getInstance();
                
          // Lấy mã người dùng từ JSON trả về của Backend. 
          String maNguoiDung = responseData['id']?.toString() ?? responseData['userId']?.toString() ?? '';
          
          if (maNguoiDung.isNotEmpty) {
            await prefs.setString('ma_nguoi_dung', maNguoiDung);
            print("Lưu ma_nguoi_dung thành công: $maNguoiDung"); // Log ra màn hình để bạn dễ debug
          }
          final token = responseData['token']?.toString() ?? '';
          if (token.isNotEmpty) {
            await prefs.setString('token', token);
            print("Lưu token thành công");
          }
        // Trả về kết quả thành công và kèm theo token nếu cần lưu trữ sau này
        return {
          "success": true,
          "message": "Đăng nhập thành công",
          "token": responseData['token'],
          "role": responseData['role']
        };
      } else {
        // Trả về thông báo lỗi từ Backend (Ví dụ: "Email hoặc mật khẩu không đúng")
        return {
          "success": false,
          "message": responseData['message'] ?? "Đăng nhập thất bại"
        };
      }
    } catch (error) {
      // Bắt các lỗi mất kết nối mạng, server sập...
      _isLoading = false;
      notifyListeners();
      return {
        "success": false,
        "message": "Không thể kết nối đến máy chủ. Vui lòng thử lại sau!"
      };
    }
  }

  // Hàm kết nối API Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register(String fullName, String email, String password, String confirmPassword) async {
    // Kiểm tra cơ bản ở Frontend trước khi gửi lên Server
    if (password != confirmPassword) {
      return {"success": false, "message": "Mật khẩu xác nhận không khớp!"};
    }
    if (fullName.isEmpty || password.isEmpty || email.isEmpty) {
      return {"success": false, "message": "Vui lòng điền đầy đủ thông tin!"};
    }

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/register'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "password": password,
          "role": "Benh_nhan"
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": "Đăng ký thành công!"};
      } else {
        return {
          "success": false, 
          "message": responseData['message'] ?? "Đăng ký thất bại"
        };
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ. Vui lòng thử lại!"};
    }
  }

  // Hàm lấy ID người dùng đã lưu trong SharedPreferences (sau khi đăng nhập thành công)
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ma_nguoi_dung');
  }

  // Hàm xóa sạch dữ liệu khi người dùng bấm Đăng xuất (Logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('ma_nguoi_dung');
    await prefs.remove('userId');
    await prefs.remove('token');
    await prefs.remove('role');
    
    notifyListeners();
  }

  // Hàm kết nối API Xác thực OTP (sau khi người dùng nhận được mã OTP qua email)
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    // Gọi đến route /verify-otp mà bạn vừa tạo ở Node.js
    final url = Uri.parse('$_baseUrl/verify-otp'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email, // Backend cần biết email nào đang gửi mã
          "otp": otp      // Và mã 6 số là gì
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": responseData['message'] ?? "Xác thực thành công!"};
      } else {
        return {
          "success": false, 
          "message": responseData['message'] ?? "Xác thực thất bại"
        };
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ. Vui lòng thử lại!"};
    }
  }

  // Hàm kết nối API Quên Mật Khẩu
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        return {"success": true, "message": responseData['message'] ?? "Đã gửi liên kết khôi phục!"};
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? "Không thể gửi yêu cầu"
        };
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ. Vui lòng thử lại sau!"};
    }
  }

  // Hàm kết nối API Đăng nhập OAuth (Google/Facebook)
  Future<Map<String, dynamic>> oauthLogin({
    required String email,
    required String fullName,
    required String provider, 
    required String providerId,
    required String avatar,
  }) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/oauth-login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "fullName": fullName,
          "provider": provider,
          "providerId": providerId,
          "avatar": avatar,
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        // Lưu thông tin đăng nhập tương tự luồng đăng nhập thường để đồng bộ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token'] ?? '');
        await prefs.setString('role', responseData['role'] ?? '');
        await prefs.setInt('userId', responseData['id'] ?? 0);
        
        return {"success": true, "message": "Đăng nhập thành công!"};
      } else {
        return {"success": false, "message": responseData['message'] ?? "Đăng nhập thất bại"};
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ!"};
    }
  }
}