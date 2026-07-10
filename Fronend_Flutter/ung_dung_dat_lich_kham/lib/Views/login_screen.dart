import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đã thêm import đồng bộ UI
import 'main_screen.dart';
import 'forgot_password_screen.dart';
import 'doctor/doctor_main_screen.dart';
import 'signup_screen.dart';
import 'doctor/doctor_signup_screen.dart'; 
import 'admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;

  // Đã xóa các màu hardcode, sử dụng từ ui_constants.dart

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white, // Đồng bộ nền trắng
      appBar: AppBar(
        backgroundColor: kPrimaryColor, // Sử dụng màu chuẩn
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Đăng Nhập',
          style: kHeaderTextStyle, // Sử dụng style chuẩn
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding), // Đồng bộ lề 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: kSpacingLarge),
            
            const Icon(Icons.local_hospital, size: 80, color: kPrimaryColor),
            const SizedBox(height: kSpacingLarge),

            _buildLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hintText: 'example@healthcare.com',
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
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: kPrimaryColor),
                ),
              ),
            ),
            const SizedBox(height: kSpacingSmall),

            ElevatedButton(
              onPressed: authVM.isLoading
                  ? null
                  : () async {
                      final result = await authVM.login(
                        _emailController.text.trim(),
                        _passController.text,
                      );

                      if (!context.mounted) return;

                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đăng nhập thành công!')),
                        );
                        
                        final String role = result['role'] ?? '';

                        if (role == 'Bac_si') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const DoctorMainScreen()),
                          );
                        } else if (role == 'Benh_nhan') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quyền truy cập không hợp lệ trên ứng dụng này.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc chuẩn 20
                ),
                elevation: 0,
              ),
              child: authVM.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Đăng Nhập', style: kButtonTextStyle), // Sử dụng text style chuẩn
            ),
            
            const SizedBox(height: kSpacingLarge),
            const Center(
              child: Text(
                'hoặc đăng nhập bằng',
                style: TextStyle(color: kGreyTextColor),
              ),
            ),
            const SizedBox(height: kSpacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _handleGoogleSignIn(context),
                  child: _buildSocialButton('G'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản? ', style: TextStyle(color: kGreyTextColor, fontSize: 15)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                  },
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn là chuyên gia y tế? ', style: TextStyle(color: kGreyTextColor, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorSignupScreen())),
                  child: const Text(
                    'Đăng ký đối tác', 
                    style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Divider(color: kBorderCyan, height: 1),
            const SizedBox(height: 15),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, color: kPrimaryColor, size: 18),
                label: const Text(
                  'Cổng đăng nhập dành cho Quản trị viên',
                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: kLabelTextStyle), // Sử dụng style chuẩn
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kLightCyanBg1, // Nền ô nhập liệu chuẩn
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc chuẩn 20
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: kPrimaryColor, // Màu chuẩn
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '103197146336-5c1d0231e2327rmp9793808d43i3hhfo.apps.googleusercontent.com',
        scopes: <String>['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; 

      if (!context.mounted) return;
      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      final result = await authVM.oauthLogin(
        email: googleUser.email,
        fullName: googleUser.displayName ?? 'Người dùng',
        provider: 'Google',
        providerId: googleUser.id,
        avatar: googleUser.photoUrl ?? '',
      );

      if (!context.mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Google thành công!')),
        );
        
        final String role = result['role'] ?? 'Benh_nhan';
        
        if (role == 'Bac_si') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorMainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (error) {
      debugPrint("LỖI ĐĂNG NHẬP GOOGLE: $error"); 
      
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('popup_closed') || errorString.contains('sign_in_canceled') || errorString.contains('canceled')) {
        return; 
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thật sự: $error')), 
        );
      }
    }
  }
}