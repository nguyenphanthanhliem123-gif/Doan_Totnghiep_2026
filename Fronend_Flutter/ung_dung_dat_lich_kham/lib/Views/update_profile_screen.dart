import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart'; 
import '../constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // ✅ ĐÃ THÊM: Controller cho Số điện thoại
  final TextEditingController _phoneController = TextEditingController();

  String? fullName;
  String? avatar;
  String? address;
  int? gender;
  DateTime? birth;
  String? phone;
  
  int _selectedGender = 1; 

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
    if (!mounted) return;

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        final user = context.read<ProfileViewModel>().userProfile;
        
        if (user != null && mounted) {
          setState(() {
            _nameController.text = user.fullName;
            _addressController.text = user.address ?? '';
            _phoneController.text = user.phone ?? ''; // ✅ Gán số điện thoại cũ vào ô nhập
            _selectedGender = user.gender ?? 1; 

            fullName = user.fullName;
            address = user.address;
            gender = user.gender;
            avatar = user.avatar;
            phone = user.phone;
    
            if (![0, 1, 2].contains(_selectedGender)) _selectedGender = 1;
            if (user.dob != null) {
              birth = user.dob;
               _dobController.text = user.dob == null ? 'null' :"${user.dob!.day.toString().padLeft(2, '0')}/${user.dob!.month.toString().padLeft(2, '0')}/${user.dob!.year}";
            }
          });
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dobController.text.isNotEmpty && _dobController.text != 'null') {
      try {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initialDate, firstDate: DateTime(1900), lastDate: DateTime.now(), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor, onPrimary: Colors.white, onSurface: Colors.black)),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() { _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}"; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose(); // ✅ Giải phóng RAM
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
          decoration: const BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
          child: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Cập nhật hồ sơ', style: kHeaderTextStyle), centerTitle: true),
        ),
      ),
      body: profileVM.isLoading
      ? const Center(child: CircularProgressIndicator(),)
      : user == null 
        ? const Center(child: Text("Không thể tải thông tin tài khoản."))
        : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kPrimaryColor, width: 3), image: const DecorationImage(fit: BoxFit.cover, image: NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: InkWell(
                      onTap: () {},
                      child: Container(height: 36, width: 36, decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Họ và Tên', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),

                  // ✅ ĐÃ THÊM: Khu vực nhập Số điện thoại
                  const Text('Số điện thoại', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildTextField(_phoneController, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),

                  const Text('Ngày sinh (DD/MM/YYYY)', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildTextField(_dobController, icon: Icons.calendar_month, readOnly: true, onTap: () => _selectDate(context)),
                  const SizedBox(height: 20),

                  const Text('Giới tính', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildGenderComboBox(),
                  const SizedBox(height: 20),

                  const Text('Địa chỉ', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildTextField(_addressController, icon: Icons.location_on_outlined),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () async {
                  final _fullName = _nameController.text.trim();
                  final _address = _addressController.text.trim();
                  final _phone = _phoneController.text.trim(); // ✅ Lấy giá trị số điện thoại

                  if(_fullName.isEmpty || _address.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không được bỏ trống Họ tên và Địa chỉ.')));
                    return;
                  }

                  DateTime selectedBirth = DateTime.now(); 
                  String dobUI = _dobController.text.trim();
                  if (dobUI.isNotEmpty && dobUI != 'null') {
                    try {
                      List<String> parts = dobUI.split('/');
                      if (parts.length == 3) selectedBirth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    } catch (e) {}
                  }

                  try {
                    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                    // ✅ ĐÃ SỬA: Hàm updateProfile truyền 6 tham số (thêm _phone)
                    await context.read<ProfileViewModel>().updateProfile(
                      _fullName, 
                      selectedBirth, 
                      avatar ?? '',  
                      _address,      
                      _selectedGender,
                      _phone 
                    );

                    if (context.mounted) Navigator.pop(context); 
                    if (!context.mounted) return;

                    if (context.read<ProfileViewModel>().updateProfileResult == true) {
                      context.read<HealthRecordViewModel>().loadHealthRecord();

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green));
                    } else {
                      final errorText = context.read<ProfileViewModel>().errorMessage.isNotEmpty ? context.read<ProfileViewModel>().errorMessage : 'Cập nhật thất bại, vui lòng thử lại!';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $errorText'), backgroundColor: Colors.red));
                    }

                    Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: const Text('Lưu cập nhật', style: kButtonTextStyle),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ✅ ĐÃ SỬA: Thêm tham số keyboardType để hiển thị bàn phím số
  Widget _buildTextField(TextEditingController controller, {IconData? icon, bool readOnly = false, VoidCallback? onTap, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, readOnly: readOnly, onTap: onTap, keyboardType: keyboardType,
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor, filled: true, suffixIcon: icon != null ? Icon(icon, color: kGreyTextColor) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildGenderComboBox() {
    final Map<int, String> genderMap = { 1: 'Nam', 0: 'Nữ' };
    return DropdownButtonFormField<int>(
      value: _selectedGender, 
      decoration: InputDecoration(fillColor: kInputBackgroundColor, filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      icon: const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
      items: genderMap.entries.map((entry) => DropdownMenuItem<int>(value: entry.key, child: Text(entry.value, style: const TextStyle(color: Colors.black87, fontSize: 16)))).toList(),
      onChanged: (int? newValue) { if (newValue != null) setState(() => _selectedGender = newValue); },
    );
  }
}