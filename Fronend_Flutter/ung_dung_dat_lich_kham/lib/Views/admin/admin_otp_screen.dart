import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminOtpScreen extends StatefulWidget {
  final String email;
  const AdminOtpScreen({super.key, required this.email});

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _otpControllers) { c.dispose(); }
    for (var n in _focusNodes) { n.dispose(); }
    super.dispose();
  }

  String getOtp() => _otpControllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: kPrimaryColor),
                const SizedBox(height: kSpacingLarge),
                const Text('Bảo mật 2 Lớp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextColor)),
                const SizedBox(height: 12),
                Text('Nhập mã OTP gửi tới ${widget.email}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: kGreyTextColor, height: 1.5)),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authVM.isLoading ? null : () async {
                      String otpCode = getOtp();
                      if (otpCode.length == 6) {
                        final result = await authVM.verifyOtp(widget.email, otpCode);
                        if (!mounted) return;
                        
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập Admin thành công!')));
                          // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ 6 số!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                    ),
                    child: authVM.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Xác Nhận', style: kButtonTextStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45, height: 55,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: _focusNodes[index].hasFocus ? kPrimaryColor : kBorderCyan, width: 2),
      ),
      child: TextField(
        controller: _otpControllers[index], focusNode: _focusNodes[index],
        keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          else if (value.isEmpty && index > 0) FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        },
      ),
    );
  }
}