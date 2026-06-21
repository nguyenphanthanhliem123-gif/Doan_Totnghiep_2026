import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';

class APIReviewService{
  Future<bool?> createReview(int appointmentID, int star, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return null;

    try{
      final res = await http.post(
        Uri.parse('$BASE_URL/api/reviews/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Ma_lich_hen': appointmentID,
          'So_sao' : star,
          'Noi_dung': content 
        })
      );
      final data = jsonDecode(res.body);
      if(res.statusCode == 200){
        return true;
      }
      else{
        print('Lỗi createReview: ${data['message']}');
        return false;
      }
    }catch(e){
      throw Exception("Lỗi createReview: ${e.toString()}");
    }
  }
}