import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/schedule_config_model.dart';

class APIScheduleConfig{
  Future<bool> saveScheduleConfig(DoctorScheduleConfigModel config) async{
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if(token == null ) return false;

      final res = await http.post(
          Uri.parse('$BASE_URL/api/doctors/schedule/config/create'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(config.toJson()),
      );

      final result = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return result['succeeded'] ?? false;
      }
      print("Lỗi lưu cấu hình lịch: ${result['message']}");
      return false;
    }catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }

  Future<DoctorScheduleConfigModel?> getScheduleConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final res = await http.get(
        Uri.parse('$BASE_URL/api/doctors/schedule/config'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result['succeeded'] == true && result['data'] != null) {
          // Parse dữ liệu từ Backend trả về
          final configData = result['data']['config'];
          final weeklyData = result['data']['weeklySchedule'] as List;

          return DoctorScheduleConfigModel(
            slotTime: configData?['Thoi_gian_slot'] ?? 20,
            breakTime: configData?['Thoi_gian_nghi'] ?? 5,
            weeklySchedule: weeklyData.map((e) => WeeklyScheduleItem(
              thu: e['Thu_trong_tuan'],
              buoi: e['Buoi'],
              gioBatDau: e['Gio_bat_dau'].toString().substring(0, 5), // Cắt lấy HH:mm
              gioKetThuc: e['Gio_ket_thuc'].toString().substring(0, 5),
              trangThai: e['Trang_thai'],
            )).toList(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Lỗi fetch schedule config: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> generateDoctorSlots(String startDate, String endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'succeeded': false, 'message': 'Chưa đăng nhập'};

      final res = await http.post(
        Uri.parse('$BASE_URL/api/doctors/schedule/slots/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'startDate': startDate,
          'endDate': endDate,
        }),
      );

      final result = jsonDecode(res.body);
      return result; // Trả về toàn bộ map {succeeded: true/false, message: ...}
    } catch (e) {
      return {'succeeded': false, 'message': 'Lỗi server: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> reportSuddenLeave(String date, String buoi, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'succeeded': false, 'message': 'Hết phiên đăng nhập'};

      final res = await http.post(
        Uri.parse('$BASE_URL/api/doctors/schedule/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'date': date,
          'buoi': buoi,
          'reason': reason,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {'succeeded': false, 'message': 'Lỗi mạng: ${e.toString()}'};
    }
  }
}