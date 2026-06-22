import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../Models/user_model.dart';
import '../Config/BASE_URL.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIProfileService{
  Future<UserModel?> fecthProfile(int ma_nguoi_dung) async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;
    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/profile/$ma_nguoi_dung'),
        headers: {'Authorization': 'Bearer $token'}
      );
      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        final userProfile = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        print('=== USER_PROFILE: $userProfile');
        return userProfile;
      }
      else{
        final data = jsonDecode(res.body);
        print('Lỗi lấy hồ sơ người dùng: ${res.statusCode}, ${data['message']}');
        return null;
      }
    }
    catch(e){
      print('Lỗi lấy dữ liệu hồ sơ người dùng');
      return null;
    }

  }

  Future<bool> changePassword(int userID, String newPassword, String currentPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/api/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userID': userID,
          'newPassword': newPassword,
          'currentPassword': currentPassword
        }),
      );

      if (res.statusCode == 200) {
        print("Đổi mật khẩu thành công");
        return true;
      } else {
        final data = jsonDecode(res.body);
        print('Lỗi đổi mật khẩu người dùng: ${res.statusCode}, ${data['message']}');
        
        throw Exception(data['message'] ?? 'Đổi mật khẩu thất bại.');
      }
    } catch (e) {
      print('Lỗi đổi mật khẩu: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> updateProfile(String fullName, DateTime birth, String avatar, String address, int gender, String phone ) async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

    try{
      final res = await http.post(
        Uri.parse('$BASE_URL/api/profile/update-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "fullName": fullName,
          "birthDay": "${birth.year}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}", 
          "gender": gender, 
          "address": address, 
          "avatar": avatar,
          "phone": phone
        })
      );

      if(res.statusCode == 200){
        return true;
      }
      else{
        final data = jsonDecode(res.body);
        print("Lỗi cập nhật hồ sơ người dùng: ${data['message']}");

        throw Exception(data['message'] ?? "Cập nhật thông tin người dùng thất bại");
      }
    }
    catch(e){
      print("Lỗi cập nhật hồ sơ người dùng: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Lấy token đã lưu khi login
      if (token == null) return false;

      // Gọi tới đúng API upload ảnh đại diện ở Backend
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$BASE_URL/api/profile/upload-avatar')
      );
      
      // Gắn Token xác thực vào Header
      request.headers['Authorization'] = 'Bearer $token';

      // Đính kèm file ảnh với key tên là 'avatar' (Trùng khớp với req.files.avatar ở backend)
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar', 
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // Đảm bảo luôn gửi định dạng là image
        )
      );

      // Gửi request lên server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('=== STATUS CODE UPLOAD: ${response.statusCode}');
      print('=== BODY UPLOAD từ Backend: ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi uploadAvatar trên ViewModel: $e");
      return false;
    }
  }
}