import 'dart:convert';

import 'package:http/http.dart' as http;
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
}