import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/auth_viewmodel.dart'; // Đồng bộ dùng nhất quán chữ thường 'viewmodels'
import '../viewmodels/profile_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  int? userID;

  @override
  void initState() {
    super.initState();
    _loadUserID();
  }

  // Nạp ID từ AuthViewModel ngay khi màn hình khởi tạo
  Future<void> _loadUserID() async {
    try {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final savedIdStr = await authVM.getSavedUserId();
      if (savedIdStr != null && mounted) {
        setState(() {
          userID = int.tryParse(savedIdStr);
        });
      }
    } catch (e) {
      print('⚠️ Lỗi khởi tạo nạp userID từ AuthViewModel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Quản lý mật khẩu', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mật khẩu hiện tại', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_currentPassCtrl),
            const SizedBox(height: 20),
            const Text('Mật khẩu mới', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_newPassCtrl),
            const SizedBox(height: 20),
            const Text('Xác nhận mật khẩu', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_confirmPassCtrl),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final currentPass = _currentPassCtrl.text.trim();
                final newPass = _newPassCtrl.text.trim();
                final confirmPass = _confirmPassCtrl.text.trim();

                // 1. Kiểm tra tính hợp lệ của dữ liệu đầu vào
                if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
                  );
                  return;
                }

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi: Mật khẩu mới không khớp!')),
                  );
                  return;
                }

                // 2. Lấy userID hiện tại (Bảo mật kép: nếu initState chưa nạp kịp thì lấy lại tại trận)
                int? activeUserID = userID;
                if (activeUserID == null || activeUserID == 0) {
                  try {
                    final authVM = Provider.of<AuthViewModel>(context, listen: false);
                    final savedIdStr = await authVM.getSavedUserId();
                    if (savedIdStr != null) {
                      activeUserID = int.tryParse(savedIdStr);
                    }
                  } catch (e) {
                    print('⚠️ Không thể lấy userID từ AuthViewModel lúc bấm nút: $e');
                  }
                }

                // Nếu sau khi kiểm tra lại vẫn hoàn toàn trống ID
                if (activeUserID == null || activeUserID == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi: Hệ thống không xác định được danh tính. Vui lòng thử đăng nhập lại!')),
                  );
                  return;
                }

                // 3. Tiến hành gọi ProfileViewModel để đổi mật khẩu
                try {
                  final profileVM = context.read<ProfileViewModel>();

                  // Hiển thị vòng tròn Loading chặn tương tác
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  // Gọi API đổi mật khẩu xử lý bất đồng bộ
                  await profileVM.changePassword(activeUserID, newPass, currentPass);

                  if (context.mounted) Navigator.pop(context); // Tắt Loading Dialog
                  if (!context.mounted) return;

                  // 4. Xử lý kết quả phản hồi từ API thông qua ViewModel
                  if (profileVM.changePassResult == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                    );
                    // Xóa trắng form nhập liệu
                    _currentPassCtrl.clear(); 
                    _newPassCtrl.clear(); 
                    _confirmPassCtrl.clear();
                  } else {
                    final errorText = profileVM.errorMessage.isNotEmpty 
                        ? profileVM.errorMessage 
                        : 'Mật khẩu cũ không chính xác!';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Lỗi: $errorText'),
                          backgroundColor: Colors.green,
                        ));
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context); // Đảm bảo đóng loading nếu sập
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Đổi mật khẩu', style: kButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        suffixIcon: const Icon(Icons.visibility_off_outlined, color: kGreyTextColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}