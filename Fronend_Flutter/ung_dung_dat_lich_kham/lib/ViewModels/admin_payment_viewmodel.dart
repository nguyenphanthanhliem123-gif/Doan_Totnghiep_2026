import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Config/BASE_URL.dart'; // Đổi lại đường dẫn cho đúng
import '../Models/payment_admin_model.dart'; // Đổi lại đường dẫn

class AdminPaymentViewModel extends ChangeNotifier {
  List<PaymentAdminModel> _allPayments = [];
  List<PaymentAdminModel> _filteredPayments = [];
  bool _isLoading = false;

  // Tiêu chí tìm kiếm
  String _searchName = '';
  String _searchTransactionId = '';
  String _filterStatus = 'all'; 

  List<PaymentAdminModel> get filteredPayments => _filteredPayments;
  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;

  Future<void> fetchAllPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';

      final response = await http.get(
        Uri.parse('$BASE_URL/api/admin/payment'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['succeeded']) {
          _allPayments = (data['payments'] as List)
              .map((json) => PaymentAdminModel.fromJson(json))
              .toList();
          applyFilters();
        }
      }else{
        final data = json.decode(response.body);
        print('Lỗi: ${data['message']}');
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách thanh toán: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật trạng thái
  Future<bool> updatePaymentStatus(int paymentId, String newStatus, int userId, String? reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';


      final response = await http.put(
        Uri.parse('$BASE_URL/api/admin/payments/$paymentId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': newStatus,
          'userId': userId,
          'reason': reason
        }),
      );

      if (response.statusCode == 200) {
        // Cập nhật local
        final index = _allPayments.indexWhere((p) => p.maThanhToan == paymentId);
        if (index != -1) {
          fetchAllPayments(); // Tải lại để lấy dữ liệu chuẩn
        }
        return true;
      }
      else{
        print("Lỗi: ${jsonDecode(response.body)['message']}");
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái: $e");
    }
    return false;
  }

  // --- LOGIC TÌM KIẾM TƯƠNG ĐỐI (Relative Search) ---
  void searchByName(String query) {
    _searchName = query.toLowerCase();
    applyFilters();
  }

  void searchByTransactionId(String query) {
    _searchTransactionId = query.toLowerCase();
    applyFilters();
  }

  void setStatusFilter(String status) {
    _filterStatus = status;
    applyFilters();
  }

  void applyFilters() {
    _filteredPayments = _allPayments.where((payment) {
      // Tìm kiếm tương đối Tên người dùng
      final matchName = payment.tenNguoiDung?.toLowerCase().contains(_searchName) ?? false;
      
      // Tìm kiếm tương đối Mã giao dịch
      final matchTxn = payment.maGiaoDich?.toLowerCase().contains(_searchTransactionId) ?? (_searchTransactionId.isEmpty);
      
      // Lọc trạng thái
      final matchStatus = _filterStatus == 'all' || payment.trangThai == _filterStatus;

      return matchName && matchTxn && matchStatus;
    }).toList();
    notifyListeners();
  }
}