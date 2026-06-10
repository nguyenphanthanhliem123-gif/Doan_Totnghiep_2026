import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<bool?> changePassword(int userID, String newPassword, String currentPassword) async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;

    try{
      final res = await http.post(
        Uri.parse('$BASE_URL/api/auth/change-password'),
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'userID': userID,
          'newPassword': newPassword,
          'currentPassword': currentPassword
        })
      );

      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        final 
      }
    }

  }
}