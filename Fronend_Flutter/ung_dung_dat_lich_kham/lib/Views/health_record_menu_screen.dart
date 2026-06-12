import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_health_record.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/health_record_viewmodel.dart';

class HealthRecordListScreen extends StatefulWidget {
  const HealthRecordListScreen({super.key});

  @override
  State<HealthRecordListScreen> createState() => _HealthRecordListScreenState();
}

class _HealthRecordListScreenState extends State<HealthRecordListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordViewModel>().loadHealthRecord(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthVM = context.watch<HealthRecordViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Hồ Sơ Sức Khỏe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
      ),
      // Xử lý Logic hiển thị UI
      body: healthVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : (healthVM.listRecord == null || healthVM.listRecord!.isEmpty)
              ? _buildEmptyState()
              : _buildListState(healthVM),
              
      // Dấu cộng nổi
      floatingActionButton: (healthVM.listRecord != null && healthVM.listRecord!.isNotEmpty)
          ? FloatingActionButton(
              backgroundColor: kPrimaryColor,
              onPressed: () {
                if(!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddHealthRecordScreen())
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // =========================================================
  // 1. GIAO DIỆN TRỐNG
  // =========================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Biểu tượng Clipboard
          const Icon(
            Icons.assignment_outlined,
            size: 120,
            color: kPrimaryColor,
          ),
          const SizedBox(height: 30),
          const Text(
            'Bạn chưa thêm\nhồ sơ sức khỏe\ncủa bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              // TODO: Chuyển sang màn hình Form thêm hồ sơ mới
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Thêm',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 2. GIAO DIỆN DANH SÁCH
  // =========================================================
  Widget _buildListState(HealthRecordViewModel healthVM) {
    final list = healthVM.listRecord!;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.2),
              child: const Icon(Icons.person, color: kPrimaryColor),
            ),
            title: Text(
              record.recordName, // Tên hồ sơ (VD: Nguyễn Phan Thanh Liêm)
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(record.roll), // Vai trò (Chủ tài khoản, Cha, Mẹ...)
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // TODO: Chuyển sang màn hình HealthRecordMenuScreen (Chi tiết hồ sơ)
              // Nhớ gán record hiện tại vào ViewModel trước khi chuyển trang nhé!
            },
          ),
        );
      },
    );
  }
}