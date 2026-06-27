import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../Constants/ui_constants.dart';
import '../otp_verification_screen.dart';
import '../../viewmodels/specialty_viewmodel.dart';
import 'dart:typed_data';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _hocViController = TextEditingController();
  final _kinhNghiemController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _avatarImage; // Ảnh đại diện
  File? _certImage;   // Ảnh chứng chỉ
  // Thêm 2 biến byte này để hiển thị trên Web
  Uint8List? _avatarBytes;
  Uint8List? _certBytes;
  int? _selectedChuyenKhoa;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách chuyên khoa ngay khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecialtyViewModel>(context, listen: false).loadAllSpecialties();
    });
  }

  Future<void> _pickImage(bool isAvatar) async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    // Đọc file ra dạng bytes để Web hiển thị được
    final bytes = await pickedFile.readAsBytes();
    
    setState(() {
      if (isAvatar) {
        _avatarImage = File(pickedFile.path);
        _avatarBytes = bytes; // Lưu vào bytes
      } else {
        _certImage = File(pickedFile.path);
        _certBytes = bytes; // Lưu vào bytes
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final specialtyVM = Provider.of<SpecialtyViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Đăng Ký Bác Sĩ', style: kHeaderTextStyle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Hồ sơ của bạn sẽ được Quản trị viên duyệt trước khi kích hoạt.', style: TextStyle(color: kPrimaryColor, fontStyle: FontStyle.italic)),
            const SizedBox(height: 25),

            // 1. CHỌN ẢNH ĐẠI DIỆN (TRÒN)
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(color: kLightCyanBg1, shape: BoxShape.circle, border: Border.all(color: kPrimaryColor.withOpacity(0.5), width: 2)),
                      child: _avatarBytes != null
                        ? ClipOval(child: Image.memory(_avatarBytes!, fit: BoxFit.cover))
                        : const Icon(Icons.person_add_alt_1, color: kPrimaryColor, size: 40),
                    ),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Ảnh đại diện', style: TextStyle(color: kGreyTextColor, fontWeight: FontWeight.w500))),
            const SizedBox(height: 25),

            _buildLabel('Họ và tên'),
            _buildTextField(controller: _nameController, hintText: 'VD: Nguyễn Văn A'),
            
            const SizedBox(height: kSpacingSmall),
            _buildLabel('Email'),
            _buildTextField(controller: _emailController, hintText: 'example@example.com'),
            
            const SizedBox(height: kSpacingSmall),
            _buildLabel('Chuyên khoa'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: kLightCyanBg1,
                borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              ),
              child: specialtyVM.isLoading 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedChuyenKhoa,
                        hint: Text('Chọn chuyên khoa của bạn', style: TextStyle(color: kPrimaryColor.withOpacity(0.4), fontWeight: FontWeight.w500)),
                        icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500, fontSize: 16),
                        items: specialtyVM.listSpecialty?.map((ck) {
                          return DropdownMenuItem<int>(
                            value: ck.id, 
                            child: Text(ck.name),
                          );
                        }).toList() ?? [], // Trả về list rỗng nếu null
                        onChanged: (value) {
                          setState(() {
                            _selectedChuyenKhoa = value;
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: kSpacingSmall),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Học vị'), _buildTextField(controller: _hocViController, hintText: 'VD: Tiến sĩ')])),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Năm kinh nghiệm'), _buildTextField(controller: _kinhNghiemController, hintText: 'VD: 5', keyboardType: TextInputType.number)])),
              ],
            ),

            const SizedBox(height: kSpacingSmall),
            _buildLabel('Mật khẩu'),
            _buildTextField(
              controller: _passController, hintText: '***************', obscureText: _obscurePassword,
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kPrimaryColor), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
            
            const SizedBox(height: kSpacingSmall),
            _buildLabel('Xác nhận mật khẩu'),
            _buildTextField(
              controller: _confirmPassController, hintText: '***************', obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kPrimaryColor), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
            ),

            const SizedBox(height: kSpacingLarge),
            // 2. CHỌN ẢNH CHỨNG CHỈ (VUÔNG)
            _buildLabel('Ảnh chứng chỉ hành nghề'),
            InkWell(
              onTap: () => _pickImage(false),
              child: Container(
                height: 120,
                decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusLarge), border: Border.all(color: kPrimaryColor.withOpacity(0.5))),
                child: _certBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(kBorderRadiusLarge), child: Image.memory(_certBytes!, fit: BoxFit.cover))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, color: kPrimaryColor, size: 40), SizedBox(height: 8), Text('Bấm để tải ảnh lên', style: TextStyle(color: kPrimaryColor))]),
              ),
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: authVM.isLoading ? null : () async {

                final result = await authVM.registerDoctor(
                  fullName: _nameController.text.trim(), 
                  email: _emailController.text.trim(),
                  password: _passController.text, 
                  confirmPassword: _confirmPassController.text,
                  maChuyenKhoa: _selectedChuyenKhoa!, 
                  hocVi: _hocViController.text.trim(),
                  namKinhNghiem: int.tryParse(_kinhNghiemController.text.trim()) ?? 0, moTa: '', 
                  avatarBytes: _avatarBytes!, 
                  certificateBytes: _certBytes!,
                );
                
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đăng ký hồ sơ thành công! Vui lòng xác thực email.'))
                  );
  
                  // Điều hướng sang trang OTP với cấu hình dành cho Bác sĩ
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        verificationTarget: _emailController.text.trim(), 
                        isSms: false,
                        isDoctor: true,
                      )
                    )
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge))),
              child: authVM.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Gửi Yêu Cầu Đăng Ký', style: kButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), child: Text(text, style: kLabelTextStyle));
  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
      child: TextField(controller: controller, obscureText: obscureText, keyboardType: keyboardType, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500), decoration: InputDecoration(hintText: hintText, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), suffixIcon: suffixIcon)),
    );
  }
}