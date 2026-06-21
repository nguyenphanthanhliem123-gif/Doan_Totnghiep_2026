import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode; // Nhận mã OTP từ trang trước truyền qua

  const CreateNewPasswordScreen({super.key, required this.email, required this.otpCode});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final Color primaryColor = const Color(0xFF4BCBEB);
  final Color textFieldBgColor = const Color(0xFFEAF8FB);

  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('Tạo Mật Khẩu Mới', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Mật khẩu mới của bạn phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 40),

              _buildLabel('Mật khẩu mới'),
              _buildPasswordField(_newPassController, _obscureNewPass, () {
                setState(() => _obscureNewPass = !_obscureNewPass);
              }),
              const SizedBox(height: 20),
              _buildLabel('Xác nhận mật khẩu mới'),
              _buildPasswordField(_confirmPassController, _obscureConfirmPass, () {
                setState(() => _obscureConfirmPass = !_obscureConfirmPass);
              }),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: authVM.isLoading
                    ? null
                    : () async {
                        String newPass = _newPassController.text.trim();
                        String confirmPass = _confirmPassController.text.trim();

                        if (newPass.isEmpty || confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mật khẩu!')));
                          return;
                        }
                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp!')));
                          return;
                        }

                        // GỌI API ĐỔI MẬT KHẨU TỪ VIEWMODEL
                        final result = await authVM.resetPasswordWithOTP(
                          email: widget.email,
                          otp: widget.otpCode, // Lấy OTP từ trang trước
                          newPassword: newPass,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));

                        if (result['success'] == true) {
                          // Đổi pass thành công thì xóa hết lịch sử trang và về Login
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false, 
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: authVM.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Hoàn Tất Đổi Mật Khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D))),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, bool isObscure, VoidCallback toggleObscure) {
    return Container(
      decoration: BoxDecoration(color: textFieldBgColor, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Nhập mật khẩu',
          hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }
}