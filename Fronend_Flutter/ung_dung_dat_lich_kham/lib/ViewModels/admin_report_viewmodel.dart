import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint_model.dart';
import '../Config/BASE_URL.dart';

class AdminReportViewModel extends ChangeNotifier {
  List<ComplaintModel> _reports = [];
  bool _isLoading = false;

  List<ComplaintModel> get reports => _reports;
  bool get isLoading => _isLoading;

  // 1. API: Lấy danh sách khiếu nại
  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners(); 

    final prefs = await SharedPreferences.getInstance();
    // SỬA Ở ĐÂY: Lấy cả 2 trường hợp key để tránh sót token
    final token = prefs.getString('admin_token') ?? prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/api/admin/reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List<dynamic> listData = data['reports'];
          _reports = listData.map((e) => ComplaintModel.fromJson(e)).toList();
        }
      } else {
        final data = jsonDecode(res.body);
        // BỔ SUNG: In mã lỗi nếu Backend từ chối (Ví dụ: 401, 403, 500)
        debugPrint('Fetch reports failed với statusCode: ${res.statusCode}, message: ${data['message']}');
      }
    } catch (e) {
      // Nếu bị lỗi ép kiểu dữ liệu khi map JSON, dòng này sẽ in chi tiết lỗi ra Console
      debugPrint('Error fetchReports: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // 2. API: Xử lý khiếu nại (Cảnh cáo / Khóa / Bỏ qua)
  Future<bool> handleReport({
    required int reportId,
    required int targetUserId,
    required String action,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token') ?? prefs.getString('token');

    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/api/admin/reports/$reportId/handle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': action,
          'targetUserId': targetUserId,
          'adminNote': note,
        }),
      );

      if (res.statusCode == 200) {
        // Sau khi xử lý thành công, tự động tải lại danh sách mới
        await fetchReports();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error handleReport: $e');
      return false;
    }
  }
}