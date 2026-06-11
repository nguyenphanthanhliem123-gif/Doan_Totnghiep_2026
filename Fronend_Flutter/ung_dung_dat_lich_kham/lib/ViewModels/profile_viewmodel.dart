import 'package:flutter/material.dart';
import '../Models/user_model.dart';
import '../Services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final APIProfileService _apiProfileService = APIProfileService();

  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';
  bool? _changePassResult;


  UserModel? get userProfile => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool? get changePassResult => _changePassResult;

  Future<void> getUserProfile(int ma_nguoi_dung) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _userModel = await _apiProfileService.fecthProfile(ma_nguoi_dung);
      print('=== USERMODEL: $_userModel');
    }
    catch(e){
      _errorMessage = e.toString();
    }
    finally{
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfile(String newName) {
    //_currentUser.fullName = newName;

    //     notifyListeners(); // Thông báo cho tất cả các View cập nhật giao diện
    //   }

    //   bool changePassword(String currentPass, String newPass, String confirmPass) {
    //     if (newPass == confirmPass && newPass.isNotEmpty) {
    //       return true;
    //     }
    //     return false;
    //   }
    }

  Future<void> changePassword(int userID, String newPassword, String currentPassword) async {
    _isLoading = true;
    _errorMessage = '';
    _changePassResult = false; // Đặt lại trạng thái trước khi gọi
    notifyListeners();

    try {
      // Sử dụng _apiProfileService có sẵn ở đầu class
      _changePassResult = await _apiProfileService.changePassword(userID, newPassword, currentPassword);
    } catch (e) {
      // Hứng thông báo lỗi từ Service quăng ra và lưu vào _errorMessage
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _changePassResult = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
