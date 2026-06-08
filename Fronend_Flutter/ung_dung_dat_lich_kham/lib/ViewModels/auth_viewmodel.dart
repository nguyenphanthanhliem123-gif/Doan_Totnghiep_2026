import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Dữ liệu mẫu ban đầu để test
  final String _dummyEmail = "abc";
  final String _dummyPass = "123";

  // Hàm giả lập đăng nhập
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập thời gian chờ của API
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();

    // Kiểm tra dữ liệu mẫu
    if (email == _dummyEmail && password == _dummyPass) {
      return true; // Đăng nhập thành công
    }
    return false; // Sai email hoặc mật khẩu
  }

  // Hàm giả lập đăng ký
  Future<bool> register(String email, String phoneNumber, String password, String confirmPassword) async {
    if (password != confirmPassword || password.isEmpty) {
      return false; // Mật khẩu không khớp
    }

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    
    return true; // Giả lập đăng ký thành công
  }
}