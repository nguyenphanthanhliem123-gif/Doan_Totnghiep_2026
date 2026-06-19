import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 THÊM IMPORT NÀY
import '../Services/search_service.dart';

class SearchViewModel extends ChangeNotifier {
  final APISearchService _apiService = APISearchService();
  
  Timer? _debounceTimer; 
  bool _isLoading = false;
  Map<String, dynamic> _searchResults = {'doctors': [], 'specialties': [], 'clinics': []};
  
  // 🌟 Danh sách lưu lịch sử tìm kiếm
  List<String> _searchHistory = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory; // Getter cho UI lấy dữ liệu

  // 🌟 Hàm 1: Tải lịch sử tìm kiếm từ bộ nhớ máy (LocalStorage)
  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    notifyListeners();
  }

  // 🌟 Hàm 2: Thêm từ khóa vào lịch sử (Tối đa 10 mục, không trùng, mới nhất lên đầu)
  Future<void> addSearchQuery(String query) async {
    String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    // Nếu đã tồn tại từ khóa này, xóa cái cũ đi để đưa nó lên vị trí đầu tiên
    _searchHistory.remove(cleanQuery);
    
    // Thêm từ khóa mới vào đầu danh sách
    _searchHistory.insert(0, cleanQuery);

    // Giới hạn chỉ giữ lại tối đa 10 phần tử
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    notifyListeners();

    // Lưu lại danh sách mới vào bộ nhớ máy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  // 🌟 Hàm 3: Xóa một mục cụ thể trong lịch sử (Tính năng mở rộng tiện ích)
  Future<void> deleteHistoryItem(String item) async {
    _searchHistory.remove(item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  // 🌟 Hàm 4: Xóa sạch toàn bộ lịch sử
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  // Hàm được gọi mỗi khi người dùng gõ 1 phím
  void onSearchQueryChanged(String query) {
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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        _searchResults = await _apiService.searchGlobal(query.trim());
        
        // 🌟 KHI TÌM KIẾM THÀNH CÔNG, LƯU TỪ KHÓA NÀY VÀO LỊCH SỬ
        await addSearchQuery(query);
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