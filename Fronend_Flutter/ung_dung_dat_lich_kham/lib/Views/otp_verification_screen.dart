import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../Constants/ui_constants.dart'; 
import 'login_screen.dart';
import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationTarget;
  final bool isSms;
  final bool isForgotPassword;
  final bool isDoctor; // 🌟 THÊM BIẾN NÀY ĐỂ PHÂN LOẠI LUỒNG BÁC SĨ

  const OtpVerificationScreen({
    super.key,
    required this.verificationTarget,
    required this.isSms,
    this.isForgotPassword = false,
    this.isDoctor = false, // 🌟 Mặc định là false để người dùng cũ ko bị lỗi
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) { controller.dispose(); }
    for (var node in _focusNodes) { node.dispose(); }
    super.dispose();
  }

  String getOtp() {
    return _otpControllers.map((c) => c.text).join();
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
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(
                  widget.isSms ? Icons.mark_chat_unread_outlined : Icons.mark_email_unread_outlined,
                  size: 80,
                  color: kPrimaryColor,
                ),
                const SizedBox(height: kSpacingLarge),
                Text(
                  widget.isDoctor ? 'Xác Thực Hồ Sơ Bác Sĩ' : 'Xác Thực Tài Khoản',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                ),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
                
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authVM.isLoading 
                        ? null 
                        : () async {
                            String otpCode = getOtp();
                            if (otpCode.length == 6) {
                              if (widget.isForgotPassword) {
                                final result = await authVM.verifyResetOTP(widget.verificationTarget, otpCode);
                                if (!mounted) return;
                                
                                if (result['success'] == true) {
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent)
                                  );
                                }
                              }
                              // LUỒNG ĐĂNG KÝ BÁC SĨ
                              else if (widget.isDoctor) {
                                final result = await authVM.verifyDoctorOTP(widget.verificationTarget, otpCode);
                                if (!mounted) return;

                                if (result['success'] == true) {
                                  // Hiện Dialog thông báo nghiệp vụ chờ duyệt cực chuyên nghiệp
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 10),
                                          Text('Nộp Hồ Sơ Thành Công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: const Text('Hồ sơ chuyên môn của Bác sĩ đã được xác thực email thành công và đang nằm trong danh sách chờ phê duyệt từ Ban quản trị hệ thống.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                              (Route<dynamic> route) => false,
                                            );
                                          },
                                          child: const Text('Quay về Đăng nhập', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent)
                                  );
                                }
                              }
                              // LUỒNG ĐĂNG KÝ BỆNH NHÂN MẶC ĐỊNH
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
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
                    ),
                    child: authVM.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Xác Nhận', style: kButtonTextStyle),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        )
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45, height: 55,
      decoration: BoxDecoration(
        color: kLightCyanBg1,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? kPrimaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index], focusNode: _focusNodes[index],
        keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }
}