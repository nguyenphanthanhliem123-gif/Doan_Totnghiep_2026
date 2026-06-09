// import 'package:flutter/material.dart';
// import '../Models/user_model.dart';

// class ProfileViewModel extends ChangeNotifier {
//   // Dữ liệu mẫu ban đầu
//   final UserModel _currentUser = UserModel(
//     fullName: 'Jane Doe',
//     email: 'Janedoe@example.com',
//     phone: '+123 567 89000',
//   );

//   UserModel get currentUser => _currentUser;

//   void updateProfile(String newName) {
//     _currentUser.fullName = newName;

//     notifyListeners(); // Thông báo cho tất cả các View cập nhật giao diện
//   }

//   bool changePassword(String currentPass, String newPass, String confirmPass) {
//     if (newPass == confirmPass && newPass.isNotEmpty) {
//       return true;
//     }
//     return false;
//   }
// }