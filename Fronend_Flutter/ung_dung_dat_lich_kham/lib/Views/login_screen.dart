import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 🌟 Import Google Sign In
import '../viewmodels/auth_viewmodel.dart';
import 'main_screen.dart';
import 'forgot_password_screen.dart';
import 'doctor/doctor_main_screen.dart';
import 'signup_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;

  final Color primaryColor = const Color(0xFF4BCBEB);
  final Color textFieldBgColor = const Color(0xFFEAF8FB);

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
          'Đăng Nhập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            Icon(Icons.local_hospital, size: 80, color: primaryColor),
            const SizedBox(height: 30),

            _buildLabel('Email'),
            _buildTextField(
              controller: _emailController,
              hintText: 'example@healthcare.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

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
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: authVM.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Đăng Nhập',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            
            // =========================================================
            // PHẦN UI TỪ COMMIT CŨ ĐƯỢC CHÈN VÀO ĐÂY
            // =========================================================
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'hoặc đăng nhập bằng',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
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
                const Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey, fontSize: 15)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                  },
                  child: Text(
                    'Đăng ký ngay',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CÁC HÀM TIỆN ÍCH VÀ XỬ LÝ ĐĂNG NHẬP
  // =========================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
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
        color: textFieldBgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: primaryColor.withOpacity(0.4)),
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
      decoration: BoxDecoration(
        color: primaryColor,
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
      // 1. Khởi tạo cấu hình rõ ràng: Xin quyền truy cập Email
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '103197146336-5c1d0231e2327rmp9793808d43i3hhfo.apps.googleusercontent.com',
        scopes: <String>[
          'email',
        ],
      );

      // 2. Gọi cửa sổ đăng nhập của Google hiện lên
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Nếu người dùng bấm nút "Hủy" hoặc đóng bảng Google
      if (googleUser == null) return; 

      if (!context.mounted) return;
      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      // 3. Truyền dữ liệu Google trả về xuống Backend
      final result = await authVM.oauthLogin(
        email: googleUser.email,
        fullName: googleUser.displayName ?? 'Người dùng',
        provider: 'Google',
        providerId: googleUser.id,
        avatar: googleUser.photoUrl ?? '',
      );

      if (!context.mounted) return;

      // 4. Xử lý kết quả
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Google thành công!')),
        );
        
        final String role = result['role'] ?? 'Benh_nhan';
        
        // Điều hướng dựa trên quyền truy cập
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
      // In lỗi màu đỏ ra Terminal của VS Code để bạn đọc được
      debugPrint("LỖI ĐĂNG NHẬP GOOGLE: $error"); 
      
      // Bỏ qua việc hiển thị lỗi nếu người dùng tự hủy
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('popup_closed') || errorString.contains('sign_in_canceled') || errorString.contains('canceled')) {
        return; // Thoát hàm trong im lặng, không làm phiền người dùng
      }

      if (context.mounted) {
        // Hiện thẳng cái lỗi thật lên màn hình app luôn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thật sự: $error')), 
        );
      }
    }
  }
}