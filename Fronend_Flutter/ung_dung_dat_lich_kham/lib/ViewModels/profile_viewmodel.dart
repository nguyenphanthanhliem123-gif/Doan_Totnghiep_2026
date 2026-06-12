import 'package:flutter/material.dart';
import '../Models/user_model.dart';
import '../Services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final APIProfileService _apiProfileService = APIProfileService();

  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';
  bool? _changePassResult;
  bool? _updateProfileResult;


  UserModel? get userProfile => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool? get changePassResult => _changePassResult;
  bool? get updateProfileResult => _updateProfileResult;

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

  Future<void> updateProfile(String fullName, DateTime birth, String avatar, String address, int gender) async {
    _isLoading = true;
    _errorMessage = '';
    _updateProfileResult = false;
    notifyListeners();

    try{
      _updateProfileResult = await _apiProfileService.updateProfile(fullName, birth, avatar, address, gender);

      if (_updateProfileResult == true && _userModel != null) {
        _userModel = UserModel(
          id: _userModel!.id,
          email: _userModel!.email,
          fullName: fullName,
          dob: birth,
          avatar: avatar,
          address: address,
          gender: gender,
        );
        
        notifyListeners();
      }
    }
    catch(e){
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _updateProfileResult = false;
    }
    finally{
      _isLoading = false;
      notifyListeners();
    }
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
