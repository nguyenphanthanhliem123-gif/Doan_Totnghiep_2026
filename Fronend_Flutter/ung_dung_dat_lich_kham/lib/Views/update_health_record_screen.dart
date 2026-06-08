import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

class UpdateHealthRecordScreen extends StatelessWidget {
  const UpdateHealthRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tái sử dụng hàm _buildAppBar giống hệt bên trang Menu
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            title: const Text('Hồ Sơ Sức Khỏe', style: kHeaderTextStyle),
            centerTitle: true,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildInputField('Chiều cao (cm)', '169')),
                const SizedBox(width: 15),
                Expanded(child: _buildInputField('Cân nặng (kg)', '67')),
              ],
            ),
            const SizedBox(height: 20),
            _buildComboBox('Nhóm máu', 'AB +', ['A +', 'B +', 'O +', 'AB +']),
            const SizedBox(height: 20),
            _buildComboBox('Giới tính', 'Nữ', ['Nam', 'Nữ', 'Khác']),
            
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Cập nhật', style: kButtonTextStyle),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            fillColor: kInputBackgroundColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildComboBox(String label, String value, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: kPrimaryColor),
          decoration: InputDecoration(
            fillColor: kInputBackgroundColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: items.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(color: kPrimaryColor)))).toList(),
          onChanged: (newValue) {},
        ),
      ],
    );
  }
}