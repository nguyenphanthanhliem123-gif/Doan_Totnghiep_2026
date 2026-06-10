import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/ViewModels/auth_viewmodel.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/profile_viewmodel.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  String? _maNguoiDung;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();

    if (!mounted) return;

    setState(() {
      _maNguoiDung = id;
    });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        final user = context.read<ProfileViewModel>().userProfile;
        if (user != null && mounted) {
          setState(() {
            _nameController.text = user.fullName;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final user = profileVM.userProfile;
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
            title: const Text('Hồ sơ cá nhân', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body:
      profileVM.isLoading
      ? const Center(child: CircularProgressIndicator(),)
      : user == null 
        ? const Center(child: Text("Không thể tải thông tin tài khoản."))
        : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Họ và Tên', style: kLabelTextStyle), const SizedBox(height: 8),
                  _buildTextField(_nameController),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  // Gọi logic cập nhật của ViewModel
                  context.read<ProfileViewModel>().updateProfile(
                    _nameController.text,
                    //_dobController.text,
                    //_selectedGender,
                    //_addressController.text,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công! Hãy qua tab Thông tin để xem.'))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Cập nhật', style: kButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
       
    );
  }

  Widget _buildTextField(TextEditingController controller, {IconData? icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        suffixIcon: icon != null ? Icon(icon, color: kGreyTextColor) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}