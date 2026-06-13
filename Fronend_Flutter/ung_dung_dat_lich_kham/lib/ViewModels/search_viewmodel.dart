import 'dart:async';
import 'package:flutter/material.dart';
import '../Services/search_service.dart';

class SearchViewModel extends ChangeNotifier {
  final APISearchService _apiService = APISearchService();
  
  Timer? _debounceTimer; // ✅ Bộ đếm thời gian Debounce
  
  bool _isLoading = false;
  Map<String, dynamic> _searchResults = {'doctors': [], 'specialties': [], 'clinics': []};

  bool get isLoading => _isLoading;
  Map<String, dynamic> get searchResults => _searchResults;

  // Hàm được gọi mỗi khi người dùng gõ 1 phím
  void onSearchQueryChanged(String query) {
    // 1. Hủy Timer cũ nếu người dùng vẫn đang gõ liên tục
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.trim().isEmpty) {
      _searchResults = {'doctors': [], 'specialties': [], 'clinics': []};
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // 2. Thiết lập Timer mới: Chỉ gọi API sau khi người dùng DỪNG GÕ 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        _searchResults = await _apiService.searchGlobal(query.trim());
      } catch (e) {
        print(e);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}