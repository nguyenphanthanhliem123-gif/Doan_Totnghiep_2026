import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'admin_login_screen.dart';
import 'admin_pending_doctors_screen.dart';
import 'admin_specialty_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchDashboardStats();
      context.read<AdminViewModel>().initSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final stats = adminVM.dashboardData;

    return Scaffold(
      key: _scaffoldKey, // Gắn key để mở Drawer từ icon custom
      backgroundColor: kLightCyanBg2,
      // ==========================================
      // THÊM MENU TRƯỢT (DRAWER) ĐỂ ĐIỀU HƯỚNG
      // ==========================================
      drawer: _buildAdminDrawer(context),
      body: SafeArea(
        child: adminVM.isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : RefreshIndicator(
                color: kPrimaryColor,
                onRefresh: () => context.read<AdminViewModel>().fetchDashboardStats(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kSpacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: kSpacingLarge),

                      const Text('Yêu Cầu Cần Xử Lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionCard(
                            title: 'Hồ sơ chờ duyệt',
                            value: stats['pendingDoctors'].toString(),
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingDoctorsScreen()));
                            }
                          ),
                          const SizedBox(width: 15),
                          _buildActionCard(
                            title: 'Khiếu nại chưa xử lý',
                            value: stats['openComplaints'].toString(),
                            icon: Icons.report_problem_outlined,
                            color: Colors.redAccent,
                            onTap: () {
                              // Chuyển sang màn hình Xử lý khiếu nại (Chưa tạo)
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingLarge),

                      const Text('Tình Hình Hôm Nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                      const SizedBox(height: 12),
                      _buildBigGradientCard(
                        value: stats['todayAppointments'].toString(),
                        onTap: () {
                          // Xem chi tiết lịch khám hôm nay (nếu cần)
                        }
                      ),
                      const SizedBox(height: kSpacingLarge),

                      const Text('Thống Kê Hệ Thống', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildOverviewCard(
                            title: 'Bác sĩ hoạt động', 
                            value: stats['activeDoctors'].toString(), 
                            icon: Icons.medical_services_outlined, 
                            color: Colors.blue,
                            onTap: () {
                              // Chuyển sang màn Quản lý Bác Sĩ (Khóa/Mở khóa)
                            }
                          ),
                          const SizedBox(width: 15),
                          _buildOverviewCard(
                            title: 'Bệnh nhân đăng ký', 
                            value: stats['totalPatients'].toString(), 
                            icon: Icons.people_outline, 
                            color: Colors.teal,
                            onTap: () {
                              // Chuyển sang màn Quản lý Bệnh nhân (Khóa/Mở khóa)
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ==========================================
  // WIDGET DRAWER (MENU CHỨA CÁC CHỨC NĂNG)
  // ==========================================
  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kPrimaryColor, kDarkCyan]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 10),
                  const Text('Hệ Thống Quản Trị', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('admin@healthcare.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.dashboard, title: 'Dashboard', onTap: () => Navigator.pop(context)),
            const Divider(),
            _buildDrawerItem(icon: Icons.fact_check_outlined, title: 'Duyệt Đăng Ký Bác Sĩ', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingDoctorsScreen()));
            }),
            _buildDrawerItem(icon: Icons.manage_accounts_outlined, title: 'Quản Lý Tài Khoản', onTap: () {}),
            const Divider(),
            _buildDrawerItem(icon: Icons.category_outlined, title: 'Danh Mục Chuyên Khoa', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSpecialtyScreen()));
            }),
            _buildDrawerItem(icon: Icons.local_hospital_outlined, title: 'Danh Mục Dịch Vụ & Phí', onTap: () {}),
            const Divider(),
            _buildDrawerItem(icon: Icons.gavel, title: 'Xử Lý Khiếu Nại', onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(title, style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // Header thay đổi để icon đầu tiên có chức năng mở Menu (Drawer)
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => _scaffoldKey.currentState?.openDrawer(), // Mở Menu trượt
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: kLightCyanBg1, shape: BoxShape.circle),
            child: const Icon(Icons.menu, color: kPrimaryColor, size: 28), // Đổi icon thành Menu
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hệ thống quản trị', style: TextStyle(color: kGreyTextColor, fontSize: 13)),
              Text('Quản Trị Viên', style: TextStyle(color: kTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryColor),
              onPressed: () => context.read<AdminViewModel>().fetchDashboardStats(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await context.read<AdminViewModel>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()), (route) => false);
                }
              },
            ),
          ],
        )
      ],
    );
  }

  // Thêm bọc InkWell và onTap cho Thẻ Hành Động
  Widget _buildActionCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kBorderRadiusLarge),
            border: Border.all(color: kBorderCyan),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Cần xử lý', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: kGreyTextColor, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // Thêm bọc InkWell và onTap cho Khối Lịch Hẹn
  Widget _buildBigGradientCard({required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPrimaryColor, kDarkCyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng số lịch hẹn khám', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text('DIỄN RA HÔM NAY', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Thêm bọc InkWell và onTap cho Thẻ Tổng Quan
  Widget _buildOverviewCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(kBorderRadiusLarge),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: kGreyTextColor, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}