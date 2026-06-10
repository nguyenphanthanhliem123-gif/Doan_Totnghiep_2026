import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  // Đã xóa _phoneController
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryColor = const Color(0xFF4BCBEB);
  final Color textFieldBgColor = const Color(0xFFEAF8FB);
  final Color labelColor = const Color(0xFF2D2D2D);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng Ký',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
            
            const SizedBox(height: 16),
            _buildLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hintText: 'example@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            _buildLabel('Mật khẩu'),
            _buildTextField(
              controller: _passController,
              hintText: '***************',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: primaryColor,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            
            const SizedBox(height: 16),
            _buildLabel('Xác nhận mật khẩu'),
            _buildTextField(
              controller: _confirmPassController,
              hintText: '***************',
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: primaryColor,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: authVM.isLoading
                  ? null
                  : () async {
                      // Nhận kết quả Map từ API
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
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: authVM.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Đăng Ký',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản? '),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); 
                  },
                  child: Text(
                    'Đăng nhập',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
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
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: labelColor),
      ),
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
        color: textFieldBgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}