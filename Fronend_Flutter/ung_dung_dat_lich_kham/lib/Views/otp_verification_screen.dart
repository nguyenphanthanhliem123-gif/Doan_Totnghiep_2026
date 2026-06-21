import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationTarget; // Email nhận mã (VD: 'khoi@gmail.com')
  final bool isSms; // false: Xác minh Email
  final bool isForgotPassword; // true: Xác minh cho quên mật khẩu, false: Xác minh cho đăng ký tài khoản mới

  const OtpVerificationScreen({
    super.key,
    required this.verificationTarget,
    required this.isSms,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final Color primaryColor = const Color(0xFF4BCBEB);
  
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Lấy chuỗi OTP 6 số hoàn chỉnh
  String getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    // Gọi Provider để lấy state (như isLoading)
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(
                widget.isSms ? Icons.mark_chat_unread_outlined : Icons.mark_email_unread_outlined,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác Thực Tài Khoản',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isSms 
                    ? 'Vui lòng nhập mã OTP gồm 6 chữ số vừa được gửi đến số điện thoại' 
                    : 'Vui lòng kiểm tra hộp thư và nhập mã xác nhận được gửi đến',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                widget.verificationTarget,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 40),
              
              // KHU VỰC NHẬP OTP (6 Ô)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),
              
              const SizedBox(height: 40),

              // NÚT XÁC NHẬN GẮN API
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authVM.isLoading 
                      ? null 
                      : () async {
                          String otpCode = getOtp();
                          if (otpCode.length == 6) {
                            if (widget.isForgotPassword) {
                                // 1. BẮT BUỘC KIỂM TRA OTP TRƯỚC
                                final result = await authVM.verifyResetOTP(widget.verificationTarget, otpCode);
                                if (!mounted) return;
                                
                                if (result['success'] == true) {
                                  // 2. Nếu ĐÚNG -> Mới cho phép qua màn hình nhập Mật khẩu
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateNewPasswordScreen(
                                        email: widget.verificationTarget, 
                                        otpCode: otpCode, 
                                      ),
                                    ),
                                  );
                                } else {
                                  // 3. Nếu SAI -> Báo lỗi đỏ ngay tại đây, cấm đi tiếp
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor: Colors.redAccent,
                                    )
                                  );
                                }
                            }
                            else {
                                final result = await authVM.verifyOTP(widget.verificationTarget, otpCode);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                                
                                if (result['success'] == true) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      (Route<dynamic> route) => false,
                                    );
                                }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập đủ 6 số!')),
                            );
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
                          'Xác Nhận',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm tạo từng ô vuông nhập số
  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero, // Giúp canh giữa số tốt hơn trên ô nhỏ
        ),
        onChanged: (value) {
          // Tự động nhảy sang ô tiếp theo khi nhập xong 1 số (đổi 3 thành 5 vì có 6 ô)
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } 
          // Tự động lùi về ô trước đó khi xóa số
          else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }
}