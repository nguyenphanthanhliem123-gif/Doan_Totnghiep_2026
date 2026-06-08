import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/health_record_viewmodel.dart';

class HealthRecordMenuScreen extends StatelessWidget {
  const HealthRecordMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = context.watch<HealthRecordViewModel>().record;

    return Scaffold(
      appBar: _buildAppBar(context, 'Hồ Sơ Sức Khỏe'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Jane Doe', style: TextStyle(fontSize: 22, color: kPrimaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giới tính: ${record.gender}', style: const TextStyle(color: kGreyTextColor)),
                    const SizedBox(height: 5),
                    const Text('Tuổi: 26', style: TextStyle(color: kGreyTextColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhóm máu: ${record.bloodType}', style: const TextStyle(color: kGreyTextColor)),
                    const SizedBox(height: 5),
                    Text('Cân nặng: ${record.weight} Kg', style: const TextStyle(color: kGreyTextColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Ghi chú sức khỏe: "),
            const SizedBox(height: 40),
            // Lưới 4 nút chức năng
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildGridItem(Icons.medication_liquid, 'Dị ứng thuốc', context, (){}),
                  _buildGridItem(Icons.set_meal, 'Dị ứng thực phẩm', context, (){}),
                  _buildGridItem(Icons.monitor_heart, 'Bệnh nền', context, (){}),
                  _buildGridItem(Icons.medical_information, 'Ghi chú sức khỏe', context, (){}),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title, BuildContext context, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Hàm tạo AppBar dùng chung cho cả 4 màn hình
  PreferredSize _buildAppBar(BuildContext context, String title) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryColor,
          //borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(title, style: kHeaderTextStyle),
          centerTitle: true,
        ),
      ),
    );
  }
}