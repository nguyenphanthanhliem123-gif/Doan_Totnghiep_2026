import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đã thêm import đồng bộ UI
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Đã xóa các màu hardcode

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white, // Đồng bộ nền
      appBar: AppBar(
        backgroundColor: kPrimaryColor, // Màu chuẩn
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng Ký',
          style: kHeaderTextStyle, // Style chuẩn
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding), // Đồng bộ lề 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            _buildLabel('Họ và tên'),
            _buildTextField(
              controller: _nameController,
              hintText: 'Nhập đầy đủ họ tên của bạn',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words, 
            ),
            
            const SizedBox(height: kSpacingSmall), // Dùng khoảng cách chuẩn
            _buildLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hintText: 'example@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: kSpacingSmall),
            _buildLabel('Mật khẩu'),
            _buildTextField(
              controller: _passController,
              hintText: '***************',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kPrimaryColor,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            
            const SizedBox(height: kSpacingSmall),
            _buildLabel('Xác nhận mật khẩu'),
            _buildTextField(
              controller: _confirmPassController,
              hintText: '***************',
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kPrimaryColor,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            
            const SizedBox(height: kSpacingLarge), // Dùng khoảng cách chuẩn
            ElevatedButton(
              onPressed: authVM.isLoading
                  ? null
                  : () async {
                      final result = await authVM.register(
                        _nameController.text.trim(),
                        _emailController.text.trim(),
                        _passController.text,
                        _confirmPassController.text,
                      );
                      
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đăng ký thành công! Vui lòng xác thực.')));
                        
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OtpVerificationScreen(
                          verificationTarget: _emailController.text.trim(), 
                          isSms: false, 
                        )));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'])));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc chuẩn
                ),
              ),
              child: authVM.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Đăng Ký', style: kButtonTextStyle), // Style chuẩn
            ),
            
            const SizedBox(height: kSpacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản? ', style: TextStyle(color: kGreyTextColor)),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); 
                  },
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: kLabelTextStyle), // Dùng style chuẩn
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kLightCyanBg1, // Nền chuẩn
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc chuẩn
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}