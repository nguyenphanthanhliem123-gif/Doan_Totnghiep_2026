import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'dart:typed_data';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Điểm cấu hình URL của API Backend Node.js
  final String _baseUrl = "$BASE_URL/api/auth";

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


      _isLoading = false;
      notifyListeners();

      // 4. Kiểm tra mã trạng thái HTTP trả về từ Backend (200 OK)
      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        final prefs = await SharedPreferences.getInstance();
                
        // Lấy mã người dùng từ JSON trả về của Backend. 
        String maNguoiDung = responseData['id']?.toString() ?? responseData['userId']?.toString() ?? '';
        int? doctorId = responseData['doctorId'];
        
        if (maNguoiDung.isNotEmpty) {
          await prefs.setString('ma_nguoi_dung', maNguoiDung);
          print("Lưu ma_nguoi_dung thành công: $maNguoiDung"); // Log ra màn hình để bạn dễ debug
        }

        // Lưu token của người dùng vào SharedPreferences để sử dụng cho các request bảo mật sau này
        final token = responseData['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          await prefs.setString('token', token);
          print("Lưu token thành công");
        }

        // Lưu role của người dùng (ví dụ: "Benh_nhan", "Bac_si", "Admin") vào SharedPreferences
        final role = responseData['role']?.toString() ?? '';
        if (role.isNotEmpty) {
          await prefs.setString('role', role);
          print("Lưu role thành công: $role");
        }

        if(doctorId != null){
          await prefs.setInt('doctorId', doctorId);
          print("Lưu doctorId thành công: $doctorId");
        }
        
        // Trả về kết quả thành công và kèm theo token nếu cần lưu trữ sau này
        return {
          "success": true,
          "message": "Đăng nhập thành công",
          "token": responseData['token'],
          "role": responseData['role'],
          "doctorId": responseData['doctorId']
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
    
    // Ưu tiên tìm key 'ma_nguoi_dung' (String)
    String? id = prefs.getString('ma_nguoi_dung');
    
    // Nếu không thấy, thử tìm key 'userId' (Int) rồi ép sang String 
    if (id == null) {
      int? intId = prefs.getInt('userId');
      if (intId != null) {
        id = intId.toString();
      }
    }
    
    return id;
  }

  // Hàm lấy mã bác sĩ (doctorId)
  Future<int?> getSavedDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ưu tiên tìm key 'ma_nguoi_dung' (String)
    int? id = prefs.getInt('doctorId');
    
    return id;
  }

  // Hàm xóa sạch dữ liệu khi người dùng bấm Đăng xuất (Logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('ma_nguoi_dung');
    await prefs.remove('userId');
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('doctorId');
    
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

  // API Yêu Cầu Gửi Mã OTP Quên Mật Khẩu
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
        // Backend sẽ trả về message báo đã gửi OTP thành công
        return {"success": true, "message": responseData['message'] ?? "Đã gửi mã OTP khôi phục!"};
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

  // Hàm kiểm tra OTP có hợp lệ không (Chốt chặn trước khi sang trang đổi pass)
  Future<Map<String, dynamic>> verifyResetOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/verify-reset-otp');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        return {"success": true, "message": "Mã OTP hợp lệ!"};
      } else {
        return {"success": false, "message": responseData['message'] ?? "Mã OTP không chính xác!"};
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ!"};
    }
  }

  // API Cập Nhật Mật Khẩu Mới (Gửi kèm OTP)
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email, 
    required String otp, 
    required String newPassword
  }) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/update-password');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        return {"success": true, "message": "Đổi mật khẩu thành công! Bạn có thể đăng nhập."};
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? "Lỗi xác thực hoặc mật khẩu không hợp lệ."
        };
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ!"};
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
        
        // Ép kiểu sang String và lưu với key 'ma_nguoi_dung' thay vì 'userId'
        String maNguoiDung = responseData['id']?.toString() ?? responseData['userId']?.toString() ?? '';
        if (maNguoiDung.isNotEmpty) {
          await prefs.setString('ma_nguoi_dung', maNguoiDung);
        }
        
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

  // Hàm kết nối API Xóa tài khoản
  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/delete-account');

    try {
      // 1. LẤY TOKEN TỪ BỘ NHỚ RA
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // 2. TRÌNH THẺ CĂN CƯỚC (TOKEN) CHO BACKEND
        },
        body: jsonEncode({"userId": userId}),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        // Nếu Server báo xóa thành công, tiến hành dọn sạch bộ nhớ cục bộ
        await logout(); 
        return {"success": true, "message": responseData['message'] ?? "Đã xóa tài khoản!"};
      } else {
        return {"success": false, "message": responseData['message'] ?? "Xóa thất bại"};
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ!"};
    }
  }

  // Hàm đăng ký riêng cho Bác sĩ
  // Hàm kết nối API Đăng ký Bác sĩ
  Future<Map<String, dynamic>> registerDoctor({
    required String fullName, required String email, required String phone, // 🌟 THÊM phone
    required String password, required String confirmPassword,
    required int maChuyenKhoa, required String hocVi, 
    required int namKinhNghiem, required String moTa,
    required Uint8List avatarBytes, 
    required Uint8List certificateBytes, 
  }) async {
    // Thêm kiểm tra rỗng cho phone
    if (password != confirmPassword) {
      return {"success": false, "message": "Mật khẩu xác nhận không khớp!"};
    }
    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || hocVi.isEmpty) {
      return {"success": false, "message": "Vui lòng điền đầy đủ thông tin!"};
    }

    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/register-doctor');
    
    try {
      var request = http.MultipartRequest('POST', url);
      
      request.fields['fullName'] = fullName;
      request.fields['email'] = email;
      request.fields['dienThoai'] = phone; // 🌟 THÊM DÒNG NÀY ĐỂ GỬI LÊN BACKEND
      request.fields['password'] = password;
      request.fields['maChuyenKhoa'] = maChuyenKhoa.toString();
      request.fields['hocVi'] = hocVi;
      request.fields['namKinhNghiem'] = namKinhNghiem.toString();
      request.fields['moTa'] = moTa;
      request.fields['role'] = "Bac_si";

      // Đính kèm File dạng BYTES thay vì Path
      request.files.add(http.MultipartFile.fromBytes('avatar', avatarBytes, filename: 'avatar.jpg'));
      request.files.add(http.MultipartFile.fromBytes('certificate', certificateBytes, filename: 'cert.jpg'));

      // 4. Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      // 5. Giải mã JSON trả về
      final responseData = jsonDecode(response.body);
      print("BACKEND TRA VE CUC NAY (DOCTOR): $responseData");

      _isLoading = false;
      notifyListeners();

      // 6. Kiểm tra kết quả trả về
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": "Đã gửi mã OTP, vui lòng xác thực!"};
      } else {
        return {
          "success": false, 
          "message": responseData['message'] ?? "Đăng ký thất bại"
        };
      }
    } catch (error) {
      // 7. Xử lý lỗi kết nối
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ. Vui lòng thử lại!"};
    }
  }

  // Hàm kết nối API Xác thực OTP dành riêng cho Bác sĩ
  Future<Map<String, dynamic>> verifyDoctorOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    // Gọi đúng đến endpoint dành cho bác sĩ mà chúng ta đã cấu hình ở Backend
    final url = Uri.parse('$_baseUrl/verify-doctor-otp'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp
        }),
      );

      final responseData = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": responseData['message'] ?? "Xác thực hồ sơ thành công!"};
      } else {
        return {
          "success": false, 
          "message": responseData['message'] ?? "Xác thực hồ sơ thất bại"
        };
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "Lỗi kết nối máy chủ. Vui lòng thử lại!"};
    }
  }
}