import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class APIAppointmentService{
  Future<bool?> updateDoneStatusAppointment(appointmentID) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      try{
        final res = await http.put(
          Uri.parse('$BASE_URL/api/appointments/doctor/status/done/$appointmentID'),
          headers: {'Authorization': 'Bearer $token'}
        );
        final data = jsonDecode(res.body);

        if(res.statusCode == 200){
          return data['succeeded'];
        }
        else{
          print('Lỗi: ${data['message']}');
          return false;
        }
      }catch(e){
        throw Exception(
          'Lỗi server: ${e.toString()}'
        );
      }
  }
}