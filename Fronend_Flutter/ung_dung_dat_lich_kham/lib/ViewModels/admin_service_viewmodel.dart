import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart';

class AdminServiceViewModel extends ChangeNotifier {
  List<dynamic> services = [];
  List<dynamic> specialties = []; // Dùng để hiển thị lên Dropdown
  bool isLoading = false;

  // 1. LẤY DANH SÁCH CÓ TÌM KIẾM VÀ LỌC
  Future<void> fetchServices({String search = '', String specId = ''}) async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final uri = Uri.parse('$BASE_URL/api/services/admin/master-services?search=$search&specId=$specId');
      
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          services = data['data'];
        }
      }
      else{
        final data = jsonDecode(res.body);
        print('Lỗi: ${data['message']}');
      }
    } catch (e) {
      print('Lỗi fetchServices: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 2. LẤY DANH SÁCH CHUYÊN KHOA (Cho Dropdown)
  Future<void> fetchSpecialties() async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/api/specialty/')); // Sửa lại URL API chuyên khoa của bạn nếu khác
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['succeeded'] == true || data['success'] == true) {
          specialties = data['data'] ?? data['specialties'] ?? [];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchSpecialties: $e');
    }
  }

  // 3. THÊM DỊCH VỤ MỚI (POST)
  Future<bool> addService(String name, int specId, double defaultPrice) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final res = await http.post(
        Uri.parse('$BASE_URL/api/services/admin/master-services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'specId': specId,
          'defaultPrice': defaultPrice
        }),
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(res.body);
        debugPrint('Lỗi Thêm: ${data['message']}');
      }
    } catch (e) {
      debugPrint('Lỗi addService: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // 4. SỬA DỊCH VỤ (PUT)
  Future<bool> updateService(int id, String name, int specId, double defaultPrice) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final res = await http.put(
        Uri.parse('$BASE_URL/api/services/admin/master-services/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'specId': specId,
          'defaultPrice': defaultPrice
        }),
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(res.body);
        debugPrint('Lỗi Sửa: ${data['message']}');
      }
    } catch (e) {
      debugPrint('Lỗi updateService: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // 5. XÓA DỊCH VỤ (DELETE)
  Future<bool> deleteService(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      final res = await http.delete(
        Uri.parse('$BASE_URL/api/services/admin/master-services/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(res.body);
        debugPrint('Lỗi Xóa: ${data['message']}'); // In ra lỗi nếu vướng khóa ngoại
      }
    } catch (e) {
      debugPrint('Lỗi deleteService: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }
}