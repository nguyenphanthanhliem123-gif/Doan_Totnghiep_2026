import 'dart:convert';

import 'package:flutter/material.dart';
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
}