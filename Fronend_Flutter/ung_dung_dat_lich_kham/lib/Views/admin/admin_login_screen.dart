import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'admin_otp_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 80, color: kPrimaryColor),
                  const SizedBox(height: 20),
                  const Text('Quản Trị Hệ Thống', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextColor)),
                  const SizedBox(height: 8),
                  const Text('Đăng nhập để truy cập Dashboard', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: kGreyTextColor)),
                  const SizedBox(height: 40),

                  _buildLabel('Email Quản trị'),
                  _buildTextField(controller: _emailController, hintText: 'admin@healthcare.com', keyboardType: TextInputType.emailAddress, icon: Icons.email_outlined),
                  const SizedBox(height: kSpacingSmall),

                  _buildLabel('Mật khẩu'),
                  _buildTextField(
                    controller: _passController, hintText: '***************', obscureText: _obscurePassword, icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kPrimaryColor),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: authVM.isLoading ? null : () async {
                      final email = _emailController.text.trim();
                      final result = await authVM.login(email, _passController.text);

                      if (!context.mounted) return;

                      if (result['success'] == true) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminOtpScreen(email: email)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                    ),
                    child: authVM.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Đăng Nhập', style: kButtonTextStyle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), child: Text(text, style: kLabelTextStyle));

  Widget _buildTextField({required TextEditingController controller, required String hintText, required IconData icon, bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
      child: TextField(
        controller: controller, obscureText: obscureText, keyboardType: keyboardType,
        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
          hintText: hintText, hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.4)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}