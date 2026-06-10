/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/profile_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Quản lý mật khẩu', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mật khẩu hiện tại', style: kLabelTextStyle), const SizedBox(height: 8),
            _buildPasswordField(_currentPassCtrl),
            const SizedBox(height: 20),
            const Text('Mật khẩu mới', style: kLabelTextStyle), const SizedBox(height: 8),
            _buildPasswordField(_newPassCtrl),
            const SizedBox(height: 20),
            const Text('Xác nhận mật khẩu', style: kLabelTextStyle), const SizedBox(height: 8),
            _buildPasswordField(_confirmPassCtrl),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                bool isSuccess = context.read<ProfileViewModel>().changePassword(
                  _currentPassCtrl.text, _newPassCtrl.text, _confirmPassCtrl.text
                );
                
                if (isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
                  _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Mật khẩu mới không khớp!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Đổi mật khẩu', style: kButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        suffixIcon: const Icon(Icons.visibility_off_outlined, color: kGreyTextColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}*/