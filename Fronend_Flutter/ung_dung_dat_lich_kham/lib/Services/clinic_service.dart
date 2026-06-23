import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/clinic_model.dart';

class APIClinicService{
  Future<List<ClinicModel>?> fetchAllClinic()async{
    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/clinics'),
      );

      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        List<dynamic> listClinic = data['clinics'];
        return listClinic.map((json) => ClinicModel.fromJson(json)).toList();
      }
      else{
        final data = jsonDecode(res.body);
        print('Lỗi: ${data['message']}');
        return null;
      }
    }catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }

  Future<bool?> updateClinicsForDoctor(List<Map<String, dynamic>> listClinics) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Phiên đăng nhập đã hết hạn.');

      final res = await http.post(
        Uri.parse('$BASE_URL/api/doctors/update-clinics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'clinics': listClinics
        })
      );

      if(res.statusCode == 200){
        return true;
      }
      else{
        final data = jsonDecode(res.body);
        print('Lỗi: ${data['message']}');
        return false;
      }
    }catch(e){
      throw Exception("Lỗi server: ${e.toString()}");
    }
  }
}