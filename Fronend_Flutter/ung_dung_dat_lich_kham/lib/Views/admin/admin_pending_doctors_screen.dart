import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../Config/BASE_URL.dart';

class AdminPendingDoctorsScreen extends StatefulWidget {
  const AdminPendingDoctorsScreen({super.key});

  @override
  State<AdminPendingDoctorsScreen> createState() => _AdminPendingDoctorsScreenState();
}

class _AdminPendingDoctorsScreenState extends State<AdminPendingDoctorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchPendingDoctors();
    });
  }

  // ========================================================
  // POPUP 1: NHẬP LÝ DO TỪ CHỐI
  // ========================================================
  void _showRejectDialog(BuildContext context, int maBacSi, String tenBacSi) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Từ chối hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập lý do từ chối bác sĩ $tenBacSi:', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'VD: Ảnh chứng chỉ bị mờ, sai thông tin...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: kLightCyanBg1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do!')));
                return;
              }
              Navigator.pop(ctx); // Đóng popup nhập lý do
              Navigator.pop(context); // Đóng luôn cả bottom sheet chi tiết
              
              final result = await context.read<AdminViewModel>().rejectDoctor(maBacSi, reasonController.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
            },
            child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // POPUP 2: XEM CHI TIẾT HỒ SƠ & ẢNH CHỨNG CHỈ
  // ========================================================
  void _showDoctorDetails(BuildContext context, Map<String, dynamic> doctor) {
    final certUrl = doctor['Anh_chung_chi'] != null ? "$BASE_URL${doctor['Anh_chung_chi']}" : null;
    final avatarUrl = doctor['Anh_dai_dien'] != null ? "$BASE_URL${doctor['Anh_dai_dien']}" : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Chiếm 85% màn hình
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            
            // Header Thông Tin Cá Nhân
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 35) : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor['Ten_nguoi_dung'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextColor)),
                      Text(doctor['Email'] ?? '', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(doctor['Ten_chuyen_khoa'] ?? '', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 30),
            
            // Thông tin chuyên môn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge('Học vị', doctor['Hoc_vi'] ?? 'Chưa rõ'),
                _buildInfoBadge('Kinh nghiệm', '${doctor['Nam_kinh_nghiem']} năm'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Ảnh Chứng Chỉ Hành Nghề
            const Text('Chứng chỉ hành nghề:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: certUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(certUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Center(child: Text('Lỗi tải ảnh chứng chỉ'))),
                      )
                    : const Center(child: Text('Không có ảnh chứng chỉ')),
              ),
            ),
            const SizedBox(height: 20),

            // Nút Thao Tác
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Từ chối'),
                    onPressed: () => _showRejectDialog(context, doctor['Ma_bac_si'], doctor['Ten_nguoi_dung']),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Phê Duyệt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.pop(ctx); // Đóng bottom sheet
                      final result = await context.read<AdminViewModel>().approveDoctor(doctor['Ma_bac_si']);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Duyệt hồ sơ bác sĩ',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: adminVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : adminVM.pendingDoctors.isEmpty
              ? const Center(child: Text('Không có hồ sơ nào đang chờ duyệt.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  itemCount: adminVM.pendingDoctors.length,
                  itemBuilder: (context, index) {
                    final doc = adminVM.pendingDoctors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: kLightCyanBg1,
                          child: const Icon(Icons.medical_services, color: kPrimaryColor),
                        ),
                        title: Text(doc['Ten_nguoi_dung'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${doc['Ten_chuyen_khoa']} - ${doc['Hoc_vi']}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => _showDoctorDetails(context, doc),
                          child: const Text('Xem', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}