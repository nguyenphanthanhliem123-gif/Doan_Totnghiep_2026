import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart'; 
import '../constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? fullName;
  String? avatar;
  String? address;
  int? gender;
  DateTime? birth;
  
  int _selectedGender = 1; 

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();

    if (!mounted) return;


    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        final user = context.read<ProfileViewModel>().userProfile;
        
        if (user != null && mounted) {
          print('=== DEBUG USER: ${user.fullName}');
          print('=== DEBUG USER: ${user.address}');
          print('=== DEBUG USER: ${user.dob.toString()}');
          setState(() {
            _nameController.text = user.fullName;
            _addressController.text = user.address ?? '';
            _selectedGender = user.gender ?? 1; 

            fullName = user.fullName;
            address = user.address;
            gender = user.gender;
            avatar = user.avatar;
    
            if (![0, 1, 2].contains(_selectedGender)) {
              _selectedGender = 1;
            }
            if (user.dob != null) {
              birth = user.dob;
               _dobController.text = user.dob == null ? 'null' :"${user.dob!.day.toString().padLeft(2, '0')}/${user.dob!.month.toString().padLeft(2, '0')}/${user.dob!.year}";
            }
          });
        } else {
          print('Không có user');
        }
      }
    }
  }

  // Hàm xử lý hiển thị DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dobController.text.isNotEmpty && _dobController.text != 'null') {
      try {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        // Bỏ qua lỗi parse, dùng ngày hiện tại
      }
    }

    // Hiển thị hộp thoại chọn ngày
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    // Nếu người dùng chọn ngày (không bấm Hủy)
    if (picked != null && mounted) {
      setState(() {
        // Cập nhật lại UI với định dạng DD/MM/YYYY
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
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
            title: const Text('Cập nhật hồ sơ', style: kHeaderTextStyle),
            centerTitle: true,
          ),
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
            
            // ================= Phần Giao diện Ảnh Đại Diện =================
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor, width: 3),
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        // Ảnh placeholder (sau này bạn thay bằng user.avatarUrl nếu có)
                        image: NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'), 
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        // TODO: Logic mở thư viện ảnh để thay đổi avatar
                      },
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ================= Phần Giao diện Các ô Nhập liệu =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Họ và Tên', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),

                  const Text('Ngày sinh (DD/MM/YYYY)', style: kLabelTextStyle), 
                  const SizedBox(height: 8),
                  // Bổ sung thuộc tính readOnly và onTap cho Ngày Sinh
                  _buildTextField(
                    _dobController, 
                    icon: Icons.calendar_month,
                    readOnly: true, // Không cho gõ bàn phím
                    onTap: () => _selectDate(context), // Gọi hàm mở Calendar
                  ),
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
            
            // ================= Nút Cập nhật =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () async {
                  final _fullName = _nameController.text.trim();
                  final _address = _addressController.text.trim();

                  if(_fullName.isEmpty || _address.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không được bỏ trống Họ tên và Địa chỉ.'))
                    );
                    return;
                  }

                  // 1. Lấy ngày sinh (DateTime) từ form hoặc dùng ngày mặc định
                  DateTime selectedBirth = DateTime.now(); // Mặc định nếu lỗi
                  String dobUI = _dobController.text.trim();
                  if (dobUI.isNotEmpty && dobUI != 'null') {
                    try {
                      List<String> parts = dobUI.split('/');
                      if (parts.length == 3) {
                        selectedBirth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                      }
                    } catch (e) {
                      print("Lỗi parse ngày: $e");
                    }
                  }

                  try {
                    final profileVM = context.read<ProfileViewModel>();

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    // 2. GỌI HÀM VỚI 5 THAM SỐ (Truyền đúng kiểu DateTime cho birth)
                    await profileVM.updateProfile(
                      _fullName, 
                      selectedBirth, // <-- Truyền biến DateTime vào đây
                      avatar ?? '',  // Avatar
                      _address,      // Address
                      _selectedGender // Gender
                    );

                    if (context.mounted) Navigator.pop(context); // Tắt Loading
                    if (!context.mounted) return;

                    // 3. KIỂM TRA KẾT QUẢ
                    if (profileVM.updateProfileResult == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
                      );
                    } else {
                      final errorText = profileVM.errorMessage.isNotEmpty 
                          ? profileVM.errorMessage 
                          : 'Cập nhật thất bại, vui lòng thử lại!';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $errorText'),
                          backgroundColor: Colors.red,
                        )
                      );
                    }

                    Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Lưu cập nhật', style: kButtonTextStyle),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Hàm tạo Widget TextField (Bổ sung readOnly và onTap)
  Widget _buildTextField(TextEditingController controller, {IconData? icon, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly, // Bổ sung
      onTap: onTap,       // Bổ sung
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        suffixIcon: icon != null ? Icon(icon, color: kGreyTextColor) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  // Hàm tạo Widget Dropdown (Combo Box) cho Giới tính map int sang String
  Widget _buildGenderComboBox() {
    // Tạo Map ánh xạ giá trị int sang chuỗi hiển thị
    final Map<int, String> genderMap = {
      1: 'Nam',
      0: 'Nữ',
    };

    return DropdownButtonFormField<int>(
      value: _selectedGender, // Nhận giá trị kiểu int
      decoration: InputDecoration(
        fillColor: kInputBackgroundColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
      // Đổ danh sách item dựa theo genderMap
      items: genderMap.entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key, // Value gửi đi là int (1, 0, 2)
          child: Text(entry.value, style: const TextStyle(color: Colors.black87, fontSize: 16)), // Text hiển thị là String
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedGender = newValue;
          });
        }
      },
    );
  }
}