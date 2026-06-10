/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/user_model.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/profile_viewmodel.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  String _selectedGender = 'Nam';

  @override
  void initState() {
    super.initState();
    Provider.of<ProfileViewModel>(context, listen: false).getUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
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
            title: const Text('Hồ sơ cá nhân', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  const Text('Ngày sinh', style: kLabelTextStyle), const SizedBox(height: 8),
                  _buildTextField(_dobController, icon: Icons.calendar_month),
                  const SizedBox(height: 20),
                  const Text('Địa chỉ', style: kLabelTextStyle), const SizedBox(height: 8),
                  _buildTextField(_addressController),
                  const SizedBox(height: 20),
                  const Text('Giới tính', style: kLabelTextStyle), const SizedBox(height: 8),
                  _buildGenderComboBox()
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

  Widget _buildGenderComboBox() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
      items: <String>['Nam', 'Nữ', 'Khác'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: kInputTextStyle),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue!;
        });
      },
    );
  }
}*/