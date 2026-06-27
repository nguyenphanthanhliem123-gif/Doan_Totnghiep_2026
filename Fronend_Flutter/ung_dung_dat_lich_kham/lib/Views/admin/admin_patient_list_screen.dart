import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'patient_appointment_history_screen.dart'; // Import màn hình lịch sử

class AdminPatientListScreen extends StatefulWidget {
  const AdminPatientListScreen({super.key});

  @override
  State<AdminPatientListScreen> createState() => _AdminPatientListScreenState();
}

class _AdminPatientListScreenState extends State<AdminPatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchAccounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final allAccounts = adminVM.accountList ?? [];

    // Lọc danh sách: Chỉ lấy Bệnh nhân + Khớp Tìm kiếm theo Tên/Email
    final filteredPatients = allAccounts.where((account) {
      final isPatient = account.role == 'Benh_nhan';
      if (!isPatient) return false;

      if (_searchQuery.isEmpty) return true;
      final name = (account.fullName).toLowerCase();
      final email = (account.email).toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

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
          'Quản lý Bệnh nhân',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: adminVM.isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : filteredPatients.isEmpty
                        ? const Center(child: Text('Không tìm thấy bệnh nhân nào', style: TextStyle(color: kGreyTextColor)))
                        : ListView.builder(
                            itemCount: filteredPatients.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return _buildPatientCard(filteredPatients[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bệnh nhân theo tên, email...',
          hintStyle: const TextStyle(color: kGreyTextColor, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: kGreyTextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchQuery = ''; });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPatientCard(dynamic account) {
    final int status = account.status ?? 1;
    final bool isDeleted = status == 0;
    final bool isActive = status == 1;
    final bool isLocked = status == 2;

    String statusText = 'Đang hoạt động';
    Color statusColor = Colors.green;

    if (isDeleted) {
      statusText = 'Đã xóa';
      statusColor = Colors.grey;
    } else if (isLocked) {
      statusText = 'Đã khóa';
      statusColor = Colors.red;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      onTap: () {
        // 🌟 BẤM VÀO SẼ RA TRANG LỊCH SỬ ĐẶT LỊCH CỦA BỆNH NHÂN ĐÓ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientAppointmentHistoryScreen(patient: account),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          border: Border.all(color: kGreyTextColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.fullName ?? 'Bệnh nhân',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDeleted ? Colors.grey : Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.email ?? '',
                    style: const TextStyle(color: kGreyTextColor, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ),
            if (!isDeleted)
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock_open_rounded : Icons.lock_person_rounded,
                  color: isLocked ? Colors.green : Colors.redAccent,
                  size: 22,
                ),
                onPressed: () {
                  if (isLocked) {
                    _showUnlockConfirmDialog(account);
                  } else if (isActive) {
                    _showLockReasonDialog(account);
                  }
                },
              )
          ],
        ),
      ),
    );
  }

  void _showLockReasonDialog(dynamic account) {
    _reasonController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khóa tài khoản bệnh nhân: ${account.fullName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(hintText: 'Nhập lý do khóa...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (_reasonController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await context.read<AdminViewModel>().lockUserAccount(userId: account.id, reason: _reasonController.text.trim());
                  },
                  child: const Text('Xác nhận khóa', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showUnlockConfirmDialog(dynamic account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mở khóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn mở khóa cho bệnh nhân ${account.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AdminViewModel>().unlockUserAccount(userId: account.id);
            },
            child: const Text('Đồng ý', style: TextStyle(color: kPrimaryColor)),
          )
        ],
      ),
    );
  }
}