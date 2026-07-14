import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/update_health_record.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/health_record_viewmodel.dart';


class HealthRecordMenuScreen extends StatefulWidget {
  final int maBenhNhan;

  const HealthRecordMenuScreen({super.key, required this.maBenhNhan});

  @override
  State<HealthRecordMenuScreen> createState() => _HealthRecordMenuScreenState();
}

class _HealthRecordMenuScreenState extends State<HealthRecordMenuScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Kích hoạt gọi API lấy dữ liệu ngay khi màn hình vừa được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordViewModel>().fetchDetailRecord(widget.maBenhNhan);
      _loadUserIdThenFetch();
    });
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();
    if (!mounted) return;

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
      }
    }

    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HealthRecordViewModel>();
    final record = viewModel.record;

    // TRẠNG THÁI 1: Chỉ hiển thị vòng xoay khi ĐANG tải thực sự
    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    // TRẠNG THÁI 2: Nếu API trả về lỗi, hiển thị lỗi lên màn hình để dễ Debug chứ không load hoài
    if (viewModel.errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            'Hồ sơ sức khỏe',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                const SizedBox(height: 15),
                Text(
                  'Không thể tải hồ sơ:\n${viewModel.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<HealthRecordViewModel>().fetchDetailRecord(widget.maBenhNhan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Thử lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // TRẠNG THÁI 3: Nếu hết load, không lỗi nhưng object vẫn trống
    if (record == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: kPrimaryColor, title: const Text('Chi Tiết Hồ Sơ')),
        body: const Center(child: Text('Không tìm thấy dữ liệu hồ sơ này.')),
      );
    }

    // TRẠNG THÁI 4: Dữ liệu tải thành công hoàn toàn
    final age = DateTime.now().year - record.dob.year;
    final formattedDob = "${record.dob.day.toString().padLeft(2, '0')}/${record.dob.month.toString().padLeft(2, '0')}/${record.dob.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi Tiết Hồ Sơ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateHealthRecordScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
            onPressed: () => _showDeleteSingleDialog(context, record.id, record.recordName, record.relationship),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(record, age),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Thông tin cơ bản'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildInfoRow(Icons.badge_rounded, 'Mã bệnh nhân', record.id.toString()),
                    _buildInfoRow(Icons.calendar_today_rounded, 'Ngày sinh', formattedDob),
                    _buildInfoRow(Icons.location_on_rounded, 'Địa chỉ', record.address),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Cảnh báo y tế'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildMedicalRow(Icons.warning_amber_rounded, 'Dị ứng', record.allergy, Colors.orange),
                    _buildMedicalRow(Icons.monitor_heart_rounded, 'Bệnh nền', record.underlyingDisease, Colors.redAccent),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN CON GIỮ NGUYÊN ---
  Widget _buildProfileHeader(dynamic record, int age) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
              child: Stack(
                children: profileViewModel.isLoading || user == null
                ? [Center(child: CircularProgressIndicator(),)]
                : [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(color: kPrimaryColor, width: 3),
                      image: DecorationImage(
                        fit: BoxFit.cover, 
                        image: (user.avatar != null && user.avatar!.isNotEmpty)
                            ? NetworkImage(user.avatar!)
                            : const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          Text(record.recordName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(record.roll, Colors.white.withOpacity(0.2)),
              const SizedBox(width: 8),
              _buildBadge('${record.gender == 1 ? "Nam" : "Nữ"} - $age tuổi', Colors.white.withOpacity(0.2)),
              const SizedBox(width: 8),
              _buildBadge('Nhóm máu: ${record.bloodType ?? "???"}', Colors.redAccent.shade100.withOpacity(0.4)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), spreadRadius: 0, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 13)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: Color(0xFF2D3748), fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedicalRow(IconData icon, String label, String? value, Color accentColor) {
    final bool hasData = value != null && value.trim().isNotEmpty && value != "Không";
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: hasData ? accentColor.withOpacity(0.1) : const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: hasData ? accentColor : kGreyTextColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 13)),
                const SizedBox(height: 3),
                Text(hasData ? value : 'Không phát hiện bất thường', style: TextStyle(color: hasData ? accentColor : const Color(0xFF2D3748), fontSize: 15, fontWeight: hasData ? FontWeight.bold : FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Hàm hiển thị Dialog Xác nhận xóa từng hồ sơ
  void _showDeleteSingleDialog(BuildContext context, int id, String name, String relationship) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Xác nhận xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa hồ sơ của "$name" không? Hành động này không thể hoàn tác.',
            style: const TextStyle(fontSize: 15, height: 1.5),
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
                if(relationship == 'Bản thân'){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Khổng thể xóa hồ sơ của bản thân.'), backgroundColor: Colors.redAccent,)
                  );
                }
                final vm = context.read<HealthRecordViewModel>();
                final success = await vm.deleteSingleRecord(id); // Gọi hàm xóa

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xóa hồ sơ thành công!'), backgroundColor: Colors.green),
                    );
                    // Bật ra ngoài màn hình danh sách
                    Navigator.pop(context); 
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(vm.errorMessage), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}