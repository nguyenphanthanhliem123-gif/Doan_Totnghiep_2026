import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _maNguoiDung;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Hiển thị hộp thoại cho người dùng chọn nguồn ảnh (Bộ sưu tập hoặc Máy ảnh)
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // Bạn có thể đổi thành ImageSource.camera tùy ý
      imageQuality: 80,            // Nén chất lượng ảnh xuống 80% cho nhẹ server
    );

    if (pickedFile != null) {
      setState(() { _isLoading = true; });

      final profileVM = context.read<ProfileViewModel>();
      File file = File(pickedFile.path);

      // Gọi hàm upload lên Backend
      await profileVM.uploadingAvatar(file);
      bool? isSuccess = profileVM.uploadAvatar;

      if (isSuccess! && _maNguoiDung != null) {
        final maNguoiDungInt = int.tryParse(_maNguoiDung!);
        if (maNguoiDungInt != null) {
          // Tải lại dữ liệu mới từ Database để cập nhật link ảnh đại diện vừa thay đổi
          await profileVM.getUserProfile(maNguoiDungInt);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải ảnh lên thất bại. Vui lòng thử lại!'), backgroundColor: Colors.red),
          );
        }
      }

      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _loadUserIdThenFetch() async {
    try {
      // 1. Lấy mã người dùng đăng nhập
      final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
      if (!mounted) return;
      
      setState(() { _maNguoiDung = id; });

      if (id != null) {
        final maNguoiDung = int.tryParse(id);
        // 2. Gọi ViewModel lấy dữ liệu profile mới nhất
        final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
        await profileVM.getUserProfile(maNguoiDung ?? 0); // Đảm bảo hàm này đã chạy xong
        
        final user = profileVM.userProfile;
        
        if (user != null) {
          // 3. 🛑 GÁN DỮ LIỆU AN TOÀN (Dùng toán tử ?? để chống nuốt lỗi Null)
          _nameController.text = user.fullName ?? '';
          _addressController.text = user.address ?? '';
          _phoneController.text = user.phone ?? '';
          
          // Kiểm tra an toàn cho Giới tính
          _selectedGender = user.gender ?? 1; 

          // Kiểm tra an toàn cho Ngày sinh
          if (user.dob != null) {
            final birthDate = user.dob!;
            _dobController.text = "${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}";
          } else {
            _dobController.text = '';
          }
        }
      }
    } catch (e) {
      // Nếu có bất kỳ lỗi gì (Null, Ép kiểu, lỗi Mạng...), log ra đây để debug
      print("❌ LỖI KHỞI TẠO UPDATE_PROFILE: $e");
    } finally {
      // 🔑 THẦN CHÚ: Bất kể thành công hay sập lỗi, bắt buộc phải tắt Loading!
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cập nhật cá nhân',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: profileVM.isLoading || _isLoading
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: kPrimaryColor, width: 3),
                        image: DecorationImage(
                          fit: BoxFit.cover, 
                          // 💡 Kiểm tra nếu trong model user có link ảnh từ DB thì hiển thị, nếu không thì lấy ảnh mặc định
                          // Chú ý: Hãy kiểm tra lại chính xác tên thuộc tính chứa ảnh trong UserModel của bạn (Vd: user.avatar hoặc user.anhDaiDien)
                          image: (user.avatar != null && user.avatar!.isNotEmpty)
                              ? NetworkImage(user.avatar!)
                              : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                        ),
                      ),
                    ),
                    // Nút tròn nhỏ có hình Camera đè góc dưới bên phải ảnh đại diện
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAndUploadImage, // Bấm vào để kích hoạt chọn ảnh
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: kPrimaryColor,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
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