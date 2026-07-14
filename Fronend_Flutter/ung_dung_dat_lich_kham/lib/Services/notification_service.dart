import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/notification_model.dart';

class APINotificationService {
  Future<List<NotificationModel>?> fecthAllNotificationByID() async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;
    

    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/notification/'),
        headers: {'Authorization': 'Bearer $token'}
      );

      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        List<dynamic> listNotification = data['notifications'];
        return listNotification.map((json) => NotificationModel.fromJson(json)).toList();
      }
      else{
        final data = jsonDecode(res.body);
        print('Lỗi : ${data['message']}');
        return null;
      }
    }catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }

  Future<bool?> markOne(int notificationID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;

    try{
      final res = await http.put(
        Uri.parse('$BASE_URL/api/notification/read/$notificationID'),
        headers: {'Authorization': 'Bearer $token'}
      );
      final data =jsonDecode(res.body);

      if(!(res.statusCode == 200)){
        print('Lỗi: ${data['message']}');
      }
      return data['succeeded'];
    }catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }

  Future<int> fecthUnReadCount() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if(token == null ) return 0;

      final res = await http.get(
        Uri.parse('$BASE_URL/api/notification/count-unread'),
        headers: {'Authorization': 'Bearer $token'}
      );

      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        print('COUNT: ${data['count']}');
        return data['count'];
      }else{
        final data = jsonDecode(res.body);
        print('Lỗi fecthUnReadCount: ${data['message']}');
        return 0;
      }
    }catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }

  Future<bool> saveFCMToken(String? FCMToken) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if(token == null ) return false;

      final res = await http.put(
        Uri.parse('$BASE_URL/api/notification/save-FCMToken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: {
          'FCMToken': FCMToken 
        }
      );

      if(res.statusCode == 200){
        print('Lưu FCMToken thành công');
        return true;
      }
      else{
        final data = jsonDecode(res.body);
        print("Lỗi ${data['message']}");
        return false;
      }
    }catch(e){
      print('Lỗi ${e.toString()}');
      return false;
    }
  }
}