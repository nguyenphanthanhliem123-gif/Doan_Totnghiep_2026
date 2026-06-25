import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/specialtyModel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';

class UpdateDoctorProfileScreen extends StatefulWidget {
  final int userId; // Nhận userId để sau khi update xong có thể load lại profile
  const UpdateDoctorProfileScreen({super.key, required this.userId});

  @override
  State<UpdateDoctorProfileScreen> createState() => _UpdateDoctorProfileScreenState();
}

class _UpdateDoctorProfileScreenState extends State<UpdateDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedImage; // Ảnh mới được chọn từ thư viện
  bool _isSubmitting = false; // Trạng thái loading toàn cục của màn hình

  final TextEditingController _hocViController = TextEditingController();
  final TextEditingController _kinhNghiemController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();

  @override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // 1. Chờ gọi cả 2 API tải xong dữ liệu
    await context.read<SpecialtyViewModel>().loadAllSpecialties();
    await context.read<DoctorViewModel>().fetchDoctorDetailForDoctor();
    
    // 2. Lấy dữ liệu đã tải từ các ViewModel ra
    final specialties = context.read<SpecialtyViewModel>().listSpecialty;
    final doctor = context.read<DoctorViewModel>().doctorDetailForDoctor;

    if (doctor != null && mounted) {
      setState(() {
        // --- ĐIỀN DỮ LIỆU CŨ VÀO CÁC Ô NHẬP LIỆU ---
        _hocViController.text = doctor.degree ?? ''; // Thừa kế học vị cũ
        _kinhNghiemController.text = doctor.experienceYears?.toString() ?? ''; // Thừa kế số năm kinh nghiệm
        _moTaController.text = doctor.description ?? ''; // Thừa kế mô tả cũ

        // --- BẪY LỖI DROPDOWN (RẤT QUAN TRỌNG) ---
        // Dropdown trong Flutter sẽ crash nếu giá trị khởi tạo không nằm trong danh sách items.
        // Đoạn này giúp kiểm tra xem ID chuyên khoa của bác sĩ có tồn tại trong danh sách chuyên khoa của hệ thống không.
        if (specialties != null && specialties.isNotEmpty) {
          // Thay 'maChuyenKhoa' bằng thuộc tính tương ứng trong DoctorModel của bạn
          final currentSpecialtyId = doctor.specialtyId; 
          
          bool isExist = specialties.any((element) => element.id == currentSpecialtyId);
          if (isExist && currentSpecialtyId != null) {
            _selectedChuyenKhoa = currentSpecialtyId;
          } else {
            _selectedChuyenKhoa = specialties.first.id; // Nếu không tìm thấy, lấy phần tử đầu tiên làm mặc định
          }
        }
      });
    }
  });
}
  
  int _selectedChuyenKhoa = 1; // Giả lập id chuyên khoa mặc định

  // 1. Hàm chọn ảnh (Giống hệt ProfileDetailScreen)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 80
    );

    if (pickedFile != null) {
      setState(() { _selectedImage = File(pickedFile.path); });
    }
  }

  // 2. Hàm xử lý khi bấm nút "Lưu Cập Nhật"
  Future<void> _submitAllData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; });

    try {
      final profileVM = context.read<ProfileViewModel>();
      final doctorVM = context.read<DoctorViewModel>();

      // --- BƯỚC A: NẾU CÓ CHỌN ẢNH THÌ UPLOAD ẢNH TRƯỚC ---
      if (_selectedImage != null) {
        await profileVM.uploadingAvatar(_selectedImage!);
        bool isAvatarSuccess = profileVM.uploadAvatar ?? false;
        if (!isAvatarSuccess) {
          throw Exception("Tải ảnh lên thất bại. Vui lòng thử lại!");
        }
      }

      // --- BƯỚC B: GỌI API CẬP NHẬT THÔNG TIN CHỮ CỦA BÁC SĨ ---
      bool isDoctorUpdateSuccess = await doctorVM.updateDoctorProfile(
        hocVi: _hocViController.text.trim(),
        soNamKinhNghiem: _kinhNghiemController.text.trim(),
        moTaBanThan: _moTaController.text.trim(),
        maChuyenKhoa: _selectedChuyenKhoa,
      );

      if (!isDoctorUpdateSuccess) {
        throw Exception(doctorVM.errorMessage);
      }

      // --- BƯỚC C: THÀNH CÔNG -> TẢI LẠI HỒ SƠ VÀ HIỆN THÔNG BÁO ---
      await profileVM.getUserProfile(widget.userId); // Load lại dữ liệu mới

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Trở về màn hình trước
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc user hiện tại để hiển thị ảnh cũ nếu chưa chọn ảnh mới
    final user = context.watch<ProfileViewModel>().userProfile;
    final specialtyVM = context.watch<SpecialtyViewModel>();
    final specialtyList = specialtyVM.listSpecialty;
    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetailForDoctor;

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
            title: const Text('Cập nhật hồ sơ Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // Đổi tên hiển thị tùy file
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: _isSubmitting || specialtyVM.isLoading || specialtyList == null || doctorVM.isLoading || doctor == null
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 1. KHU VỰC ẢNH ĐẠI DIỆN ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.blueAccent, width: 3),
                        image: DecorationImage(
                          fit: BoxFit.cover, 
                          // Nếu có chọn ảnh mới -> Hiện ảnh mới. Nếu không -> Hiện ảnh từ DB
                          image: _selectedImage != null 
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (user?.avatar != null && user!.avatar!.isNotEmpty)
                                  ? NetworkImage(user.avatar!)
                                  : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. FORM ĐIỀN THÔNG TIN BÁC SĨ ---
              TextFormField(
                controller: _hocViController,
                decoration: const InputDecoration(
                  labelText: 'Học vị / Chức danh (VD: ThS. BS)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _kinhNghiemController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số năm kinh nghiệm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_history),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<int>(
                value: _selectedChuyenKhoa,
                decoration: const InputDecoration(
                  labelText: 'Chuyên khoa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
                items: specialtyList.map((khoa) {
                  return DropdownMenuItem<int>(
                    value: khoa.id,
                    child: Text(khoa.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedChuyenKhoa = val!);
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _moTaController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả bản thân',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),

              // --- 3. NÚT LƯU THÔNG TIN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}