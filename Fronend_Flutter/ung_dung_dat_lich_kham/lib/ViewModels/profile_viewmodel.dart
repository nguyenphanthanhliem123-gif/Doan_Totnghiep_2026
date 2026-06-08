import 'package:flutter/material.dart';
import '../Models/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  // Dữ liệu mẫu ban đầu
  final UserModel _currentUser = UserModel(
    fullName: 'Jane Doe',
    email: 'Janedoe@example.com',
    phone: '+123 567 89000',
    dob: '02/05/2000',
    gender: 'Nữ',
    address: '12 Đường AB',
  );

  UserModel get currentUser => _currentUser;

  void updateProfile(String newName, String newDob, String newGender, String newAddress) {
    _currentUser.fullName = newName;
    _currentUser.dob = newDob;
    _currentUser.gender = newGender;
    _currentUser.address = newAddress;
    notifyListeners(); // Thông báo cho tất cả các View cập nhật giao diện
  }

  bool changePassword(String currentPass, String newPass, String confirmPass) {
    if (newPass == confirmPass && newPass.isNotEmpty) {
      return true;
    }
    return false;
  }
}