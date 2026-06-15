import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/doctor_schedule_model.dart';


class APIBookingService{
  Future<List<DoctorScheduleModel>?> FecthDoctorSchedule(String date) async {
    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/bookings/available-dates?q=$date'),
      );

      if (res.statusCode == 200) {
        // Giải mã utf8 để tránh lỗi hiển thị tiếng Việt tiếng có dấu
        final Map<String, dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
        
        if (body['succeeded'] == true) {
          // 🌟 Chú ý: Sử dụng chính xác key 'schesule' bị sai chính tả từ API của bạn
          final List<dynamic> scheduleList = body['schedule'] ?? [];
          final schedule = scheduleList.map((item) => DoctorScheduleModel.fromJson(item)).toList();

          print(schedule);
          
          return schedule;
        } else {
          throw Exception('Backend báo thất bại');
        }
      } else {
        throw Exception('Lỗi kết nối Server: ${res.statusCode}');
      }
    }catch (e) {
      throw Exception('Lỗi fetchDoctorSchedules: $e');
    }
  }
}