import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Constants/ui_constants.dart'; // 🌟 Import đồng bộ UI
import '../viewmodels/auth_viewmodel.dart'; 
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';

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
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý mật khẩu',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),

        /*actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () => _showFilterBottomSheet(context), // Gọi hàm mở bộ lọc
          )
        ],*/
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding), // Lề 20 chuẩn
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text('Mật khẩu hiện tại', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_currentPassCtrl),
            const SizedBox(height: kSpacingLarge),
            
            const Text('Mật khẩu mới', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_newPassCtrl),
            const SizedBox(height: kSpacingLarge),
            
            const Text('Xác nhận mật khẩu', style: kLabelTextStyle), 
            const SizedBox(height: 8),
            _buildPasswordField(_confirmPassCtrl),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () async {
                final currentPass = _currentPassCtrl.text.trim();
                final newPass = _newPassCtrl.text.trim();
                final confirmPass = _confirmPassCtrl.text.trim();

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

                if (activeUserID == null || activeUserID == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi: Hệ thống không xác định được danh tính. Vui lòng thử đăng nhập lại!')),
                  );
                  return;
                }

                try {
                  final profileVM = context.read<ProfileViewModel>();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  await profileVM.changePassword(activeUserID, newPass, currentPass);

                  if (context.mounted) Navigator.pop(context); 
                  if (!context.mounted) return;

                  if (profileVM.changePassResult == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                    );
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
                          backgroundColor: Colors.redAccent, // Thông báo lỗi nên để màu đỏ thay vì xanh
                        ));
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)), // Bo góc 20
              ),
              child: const Text('Đổi mật khẩu', style: kButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  // Cập nhật hàm tạo TextField để giống hệt CreateNewPasswordScreen
  Widget _buildPasswordField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: kLightCyanBg1, // Nền xanh nhạt chuẩn
        borderRadius: BorderRadius.circular(kBorderRadiusLarge) // Bo góc 20 chuẩn
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: '***************',
          hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.5)),
          suffixIcon: const Icon(Icons.visibility_off_outlined, color: kPrimaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}