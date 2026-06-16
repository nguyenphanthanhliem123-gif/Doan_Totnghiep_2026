import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/health_record_viewmodel.dart';

class UpdateHealthRecordScreen extends StatefulWidget {
  const UpdateHealthRecordScreen({super.key});

  @override
  State<UpdateHealthRecordScreen> createState() => _UpdateHealthRecordScreenState();
}

class _UpdateHealthRecordScreenState extends State<UpdateHealthRecordScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // ✅ ĐÃ THÊM: Controller SĐT
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();

  int _selectedGender = 1;
  String _selectedRelation = 'Khác';
  String _selectedBloodType = 'Không rõ';

  final List<String> _relations = ['Cha', 'Mẹ', 'Vợ', 'Chồng', 'Con trai', 'Con gái', 'Anh', 'Chị', 'Em', 'Chủ tài khoản', 'Khác'];
  final List<String> _bloodTypes = ['Không rõ', 'A', 'B', 'AB', 'O'];

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Vừa vào trang là đổ dữ liệu của hồ sơ hiện tại lên Form ngay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final record = context.read<HealthRecordViewModel>().record;
      if (record != null) {
        setState(() {
          _nameController.text = record.recordName;
          _phoneController.text = record.phone ?? ''; // ✅ ĐÃ THÊM: Gán SĐT cũ vào ô nhập
          _addressController.text = record.address;
          _allergyController.text = record.allergy ?? '';
          _diseaseController.text = record.underlyingDisease ?? '';
          
          _selectedDate = record.dob;
          _dobController.text = "${record.dob.day.toString().padLeft(2, '0')}/${record.dob.month.toString().padLeft(2, '0')}/${record.dob.year}";
          
          _selectedGender = record.gender;
          
          if (_relations.contains(record.roll)) {
            _selectedRelation = record.roll;
          }

          if (record.bloodType != null && _bloodTypes.contains(record.bloodType)) {
            _selectedBloodType = record.bloodType!;
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor)),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose(); // ✅ ĐÃ THÊM: Giải phóng RAM
    _dobController.dispose();
    _addressController.dispose();
    _allergyController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthVM = context.watch<HealthRecordViewModel>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Cập nhật hồ sơ', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: healthVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin bắt buộc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 15),
                  
                  _buildTextField(_nameController, 'Họ và tên *'),
                  const SizedBox(height: 15),

                  // ✅ ĐÃ THÊM: Ô nhập số điện thoại
                  _buildTextField(_phoneController, 'Số điện thoại liên hệ (Tùy chọn)', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedRelation,
                    decoration: _inputDecoration('Vai trò / Mối quan hệ *'),
                    items: _relations.map((rel) => DropdownMenuItem(value: rel, child: Text(rel))).toList(),
                    onChanged: (val) => setState(() => _selectedRelation = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(_dobController, 'Ngày sinh *', readOnly: true, onTap: () => _selectDate(context), icon: Icons.calendar_month),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<int>(
                    value: _selectedGender,
                    decoration: _inputDecoration('Giới tính *'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Nam')),
                      DropdownMenuItem(value: 0, child: Text('Nữ')),
                      DropdownMenuItem(value: 2, child: Text('Khác')),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(_addressController, 'Địa chỉ *'),
                  const SizedBox(height: 30),

                  const Text('Thông tin y tế (Tùy chọn)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _selectedBloodType,
                    decoration: _inputDecoration('Nhóm máu'),
                    items: _bloodTypes.map((blood) => DropdownMenuItem(value: blood, child: Text(blood))).toList(),
                    onChanged: (val) => setState(() => _selectedBloodType = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(_allergyController, 'Dị ứng (VD: Hải sản, Penicillin...)'),
                  const SizedBox(height: 15),

                  _buildTextField(_diseaseController, 'Bệnh nền (VD: Huyết áp, Tiểu đường...)'),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _submitForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Cập nhật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      fillColor: kInputBackgroundColor,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  // ✅ ĐÃ SỬA: Bổ sung tham số keyboardType để hiển thị đúng bàn phím số
  Widget _buildTextField(TextEditingController controller, String label, {bool readOnly = false, VoidCallback? onTap, IconData? icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType, // Bổ sung
      decoration: InputDecoration(
        labelText: label,
        fillColor: kInputBackgroundColor,
        filled: true,
        suffixIcon: icon != null ? Icon(icon, color: kGreyTextColor) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  void _submitForm(BuildContext context) async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim(); // ✅ Lấy chuỗi số điện thoại

    if (name.isEmpty || address.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ Họ tên, Ngày sinh và Địa chỉ')));
      return;
    }

    final healthVM = context.read<HealthRecordViewModel>();
    final currentRecord = healthVM.record; 
    
    if (currentRecord == null) return;

    // ✅ GỌI HÀM VÀ TRUYỀN BIẾN PHONE VÀO
    await healthVM.updateRecord(
      maBenhNhan: currentRecord.id, 
      tenHoSo: name,
      moiQuanHe: _selectedRelation,
      birthDay: _selectedDate!,
      gender: _selectedGender,
      address: address,
      phone: phone.isEmpty ? null : phone, // Truyền null nếu để trống
      nhomMau: _selectedBloodType == 'Không rõ' ? null : _selectedBloodType,
      diUng: _allergyController.text.isEmpty ? null : _allergyController.text.trim(),
      benhNen: _diseaseController.text.isEmpty ? null : _diseaseController.text.trim(),
    );

    if (!mounted) return;

    if (healthVM.updateRecordResult) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      Navigator.pop(context); // Đóng form sửa
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(healthVM.errorMessage), backgroundColor: Colors.red));
    }
  }
}