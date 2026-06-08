import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationTarget; // Nơi nhận mã (VD: '0901234567' hoặc 'khoi@gmail.com')
  final bool isSms; // true: Xác minh SĐT | false: Xác minh Email

  const OtpVerificationScreen({
    super.key,
    required this.verificationTarget,
    required this.isSms,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final Color primaryColor = const Color(0xFF4BCBEB);
  
  // Danh sách controller cho 4 ô nhập OTP (Bạn có thể tăng lên 6 ô tùy yêu cầu Backend)
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

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

  // Lấy chuỗi OTP hoàn chỉnh
  String getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
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
              // Thay đổi Icon dựa vào loại xác minh
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
              
              // Thay đổi câu văn dựa vào loại xác minh
              Text(
                widget.isSms 
                    ? 'Vui lòng nhập mã OTP gồm 4 chữ số vừa được gửi đến số điện thoại' 
                    : 'Vui lòng kiểm tra hộp thư và nhập mã xác nhận được gửi đến',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                widget.verificationTarget, // Hiển thị số điện thoại hoặc email ở đây
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              
              const SizedBox(height: 40),
              
              // Khu vực nhập OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildOtpBox(index)),
              ),
              
              const SizedBox(height: 40),
              
              // Nút Gửi lại mã
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa nhận được mã? ', style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () {
                      // Logic gọi lại API gửi OTP
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi lại mã mới!')),
                      );
                    },
                    child: Text(
                      'Gửi lại',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Nút Xác nhận
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String otpCode = getOtp();
                    if (otpCode.length == 4) {
                      // Xử lý gửi OTP lên server tại đây
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đang xác thực mã: $otpCode')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đủ 4 số!')),
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
                  child: const Text(
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FB),
        borderRadius: BorderRadius.circular(15),
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
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onChanged: (value) {
          // Tự động nhảy sang ô tiếp theo khi nhập xong 1 số
          if (value.isNotEmpty && index < 3) {
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