import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/paymentModel.dart';
import 'package:http/http.dart' as http;

class APIPaymentService{
  Future<List<PaymentModel>?> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null) return null;
    try{
      final res = await http.get(
        Uri.parse('$BASE_URL/api/payment/history'),
        headers: {'Authorization': 'Bearer $token'}
      );
      final data = jsonDecode(res.body);
      if(res.statusCode == 200){
        final List<dynamic> listPayment = data['paymentHistory'];
        return listPayment.map((json) => PaymentModel.fromJson(json)).toList();
      }else{
        final message = data['message'];
        throw Exception('Lỗi: $message');
      }
    }
    catch(e){
      throw Exception('Lỗi server: ${e.toString()}');
    }
  }
}