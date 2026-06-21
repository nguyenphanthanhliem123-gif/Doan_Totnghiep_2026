import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Services/review_service.dart';
import 'dart:convert';
import '../models/review_model.dart';

class ReviewViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _filteredReviews = [];
  List<ReviewModel> get reviews => _filteredReviews;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool? _createReview;
  bool? get createReview => _createReview; 

  double _averageRating = 0.0;
  double get averageRating => _averageRating;

  Map<int, double> _ratingDistribution = {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
  Map<int, double> get ratingDistribution => _ratingDistribution;

  int _selectedFilter = 0; // 0: Tất cả, 5: 5 sao, 4: 4 sao...
  int get selectedFilter => _selectedFilter;

  final String _baseUrl = "$BASE_URL/api/reviews/doctor";

  // Hàm gọi API để lấy danh sách đánh giá của bác sĩ theo Ma_bac_si
  Future<void> fetchReviews(int doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/$doctorId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['succeeded'] == true) {
          var list = responseData['data'] as List? ?? [];
          _allReviews = list.map((e) => ReviewModel.fromJson(e)).toList();
          
          _calculateStats();
          filterReviews(_selectedFilter); // Làm mới danh sách hiển thị theo bộ lọc hiện tại
        }
      }
    } catch (e) {
      print("Lỗi kết nối API đánh giá: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm tự động tính toán điểm trung bình và phân phối sao dạng tỷ lệ % từ DB thật
  void _calculateStats() {
    if (_allReviews.isEmpty) {
      _averageRating = 0.0;
      _ratingDistribution = {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
      return;
    }

    int totalStars = 0;
    Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var r in _allReviews) {
      totalStars += r.rating;
      if (counts.containsKey(r.rating)) {
        counts[r.rating] = counts[r.rating]! + 1;
      }
    }

    _averageRating = totalStars / _allReviews.length;

    counts.forEach((star, count) {
      _ratingDistribution[star] = count / _allReviews.length;
    });
  }

  // Hàm xử lý bộ lọc danh sách khi click chọn Tab số sao tương ứng
  void filterReviews(int star) {
    _selectedFilter = star;
    if (star == 0) {
      _filteredReviews = List.from(_allReviews);
    } else {
      _filteredReviews = _allReviews.where((r) => r.rating == star).toList();
    }
    notifyListeners();
  }

  Future<void> createReviewFuture(int appointmentID, int star, String content) async{
    _isLoading = true;
    _errorMessage ='';
    notifyListeners();

    try{
      _createReview = await APIReviewService().createReview(appointmentID, star, content);
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }
  }
}