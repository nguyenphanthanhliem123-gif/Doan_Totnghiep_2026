import 'package:flutter/material.dart';
import '../Models/user_model.dart';
import '../Services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final APIProfileService _apiProfileService = APIProfileService();

  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';


  UserModel? get userProfile => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> getUserProfile(int ma_nguoi_dung) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _userModel = await _apiProfileService.fecthProfile(ma_nguoi_dung);
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
}
