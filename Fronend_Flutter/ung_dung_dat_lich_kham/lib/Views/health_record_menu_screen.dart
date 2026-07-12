import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/health_record_detail.dart';
import 'package:ung_dung_dat_lich_kham/Views/update_health_record.dart';
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
              if(!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddHealthRecordScreen())
                );
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
              if(!mounted) return;
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HealthRecordMenuScreen(maBenhNhan: record.id)
                )
              ).then((_) {
                // ✅ CÁCH SỬA: Khi từ màn hình Chi Tiết pop lùi về đây, 
                // luôn ép ViewModel đồng bộ lại trạng thái để làm mới giao diện
                if (mounted) {
                  setState(() {}); // Kích hoạt vẽ lại giao diện
                }
              });
            },
          ),
        );
      },
    );
  }

  // Hàm hiển thị Dialog Cảnh báo trước khi xóa
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc bấm nút mới tắt được
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Cảnh báo nguy hiểm', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa TOÀN BỘ hồ sơ sức khỏe không? Dữ liệu sức khỏe sẽ bị xóa vĩnh viễn và không thể khôi phục trên hệ thống.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Đóng Dialog
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Tắt Dialog trước
                
                final vm = context.read<HealthRecordViewModel>();
                await vm.deleteAllRecords(); // Gọi hàm xóa

                if (mounted) {
                  if (vm.errorMessage.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa toàn bộ hồ sơ!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(vm.errorMessage), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Xác nhận Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}