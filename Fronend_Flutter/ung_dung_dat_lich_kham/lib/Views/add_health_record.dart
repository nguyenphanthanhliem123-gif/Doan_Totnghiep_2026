import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';

class AddHealthRecordScreen extends StatefulWidget {
  const AddHealthRecordScreen({super.key});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();

  int _selectedGender = 1; // 1: Nam, 0: Nữ
  String _selectedRelation = 'Cha';
  String _selectedBloodType = 'Không rõ';

  final List<String> _relations = ['Cha', 'Mẹ', 'Vợ', 'Chồng', 'Con trai', 'Con gái', 'Anh', 'Chị', 'Em', 'Khác'];
  final List<String> _bloodTypes = ['Không rõ', 'A', 'B', 'AB', 'O'];

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimaryColor),
          ),
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
          title: const Text('Thêm hồ sơ người thân', style: TextStyle(color: Colors.white)),
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
                  
                  _buildTextField(_nameController, 'Họ và tên người thân *'),
                  const SizedBox(height: 15),
                  
                  // Combobox Mối quan hệ
                  DropdownButtonFormField<String>(
                    value: _selectedRelation,
                    decoration: _inputDecoration('Mối quan hệ *'),
                    items: _relations.map((rel) => DropdownMenuItem(value: rel, child: Text(rel))).toList(),
                    onChanged: (val) => setState(() => _selectedRelation = val!),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(_dobController, 'Ngày sinh *', readOnly: true, onTap: () => _selectDate(context), icon: Icons.calendar_month),
                  const SizedBox(height: 15),

                  // Combobox Giới tính
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

                  // Combobox Nhóm máu
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

                  // Nút Lưu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _submitForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Lưu hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildTextField(TextEditingController controller, String label, {bool readOnly = false, VoidCallback? onTap, IconData? icon}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
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

    if (name.isEmpty || address.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ Họ tên, Ngày sinh và Địa chỉ')));
      return;
    }

    final healthVM = context.read<HealthRecordViewModel>();
    
    await healthVM.addRelativeRecord(
      tenNguoiThan: name,
      moiQuanHe: _selectedRelation,
      birthDay: _selectedDate!,
      gender: _selectedGender,
      address: address,
      nhomMau: _selectedBloodType == 'Không rõ' ? null : _selectedBloodType,
      diUng: _allergyController.text.isEmpty ? null : _allergyController.text.trim(),
      benhNen: _diseaseController.text.isEmpty ? null : _diseaseController.text.trim(),
    );

    if (!mounted) return;

    if (healthVM.addRecordResult) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm hồ sơ thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      Navigator.pop(context); // Quay về trang danh sách hồ sơ
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(healthVM.errorMessage), backgroundColor: Colors.red));
    }
  }
}