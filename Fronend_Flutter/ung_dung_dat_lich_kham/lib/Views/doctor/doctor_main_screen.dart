import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor/doctor_menu_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/notification_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/notification_viewmodel.dart';
import '../../viewmodels/doctor_appointment_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../Constants/ui_constants.dart';
import 'doctor_appointment_screen.dart';
import 'doctor_service_screen.dart'; 

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({Key? key}) : super(key: key);

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final idStr = await context.read<AuthViewModel>().getSavedUserId();
    if (idStr != null) {
      final maNguoiDung = int.tryParse(idStr);
      if (maNguoiDung != null) {
        if (mounted) {
          await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        }
      }
    }
    if (mounted) {
      await context.read<DoctorAppointmentViewModel>().loadDashboard();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      context.read<DoctorAppointmentViewModel>().loadDashboard();
    } else if (index == 1) {
      context.read<DoctorAppointmentViewModel>().loadDashboard();
    }
  }

  List<Widget> get _pages => [
    DoctorDashboardScreen(onNavigate: _onItemTapped), 
    const DoctorAppointmentScreen(),
    const DoctorServiceManagementScreen(),
    const DoctorMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor, // 🌟 Đồng bộ màu chuẩn hệ thống
        unselectedItemColor: kGreyTextColor,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch làm việc'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Dịch vụ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

// =====================================================================
// MÀN HÌNH DASHBOARD BÁC SĨ
// =====================================================================
class DoctorDashboardScreen extends StatelessWidget {
  final Function(int) onNavigate; 
  const DoctorDashboardScreen({Key? key, required this.onNavigate}) : super(key: key);

  ImageProvider _safeAvatar(String? url) {
    if (url == null || url.trim().isEmpty || !url.startsWith('http')) {
      return const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png');
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorAppointmentViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2, // 🌟 Đồng bộ nền sáng mịn màng toàn hệ thống
      body: SafeArea(
        child: doctorVM.isLoading && doctorVM.pendingAppointments.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: () async {
                await context.read<DoctorAppointmentViewModel>().loadDashboard();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kSpacingSmall),
                    _buildHeader(context, doctorVM),
                    const SizedBox(height: 20),
                    _buildQuickStats(doctorVM),
                    const SizedBox(height: 20),
                    _ExpandableRevenueCard(
                      totalRevenue: doctorVM.todayRevenue, 
                      details: doctorVM.revenueDetails
                    ),
                    const SizedBox(height: kSpacingLarge),
                    _buildPendingAppointments(context, doctorVM),
                    const SizedBox(height: kSpacingLarge),
                    _buildTodayAppointments(doctorVM),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DoctorAppointmentViewModel doctorVM) {
    final profileVM = context.watch<ProfileViewModel>();
    final user = profileVM.userProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            backgroundImage: _safeAvatar(user?.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xin chào,', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Text(
                  user?.fullName ?? 'Bác sĩ', 
                  style: const TextStyle(color: kTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          NotificationBadge(),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: doctorVM.isDoctorActive,
                activeColor: kPrimaryColor,
                onChanged: (val) async {
                  final result = await context.read<DoctorAppointmentViewModel>().toggleActiveStatus(val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success'] 
                          ? (val ? Colors.green : Colors.orange) 
                          : Colors.red,
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  doctorVM.isDoctorActive ? 'Sẵn sàng' : 'Đang bận', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: doctorVM.isDoctorActive ? kPrimaryColor : Colors.redAccent
                  )
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickStats(DoctorAppointmentViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Row(
        children: [
          _buildStatCard('Ca chờ duyệt', vm.pendingCount.toString(), Icons.pending_actions, Colors.orange),
          const SizedBox(width: 10),
          _buildStatCard('Khám hôm nay', vm.todayCount.toString(), Icons.event_available, kPrimaryColor),
          const SizedBox(width: 10),
          _buildStatCard('Đã hủy', vm.cancelledCount.toString(), Icons.cancel_presentation, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(kBorderRadiusLarge), // 🌟 Bo tròn 20 chuẩn hệ thống
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: kGreyTextColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAppointments(BuildContext context, DoctorAppointmentViewModel vm) {
    if (vm.pendingAppointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Text('Không có lịch chờ xác nhận mới.', style: TextStyle(color: kGreyTextColor)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Text('Lịch Chờ Xác Nhận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vm.pendingAppointments.length,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemBuilder: (context, index) {
              final item = vm.pendingAppointments[index];
              final localTime = DateTime.parse(item['Thoi_gian_Bdau']).toLocal();
              final timeStr = "${localTime.day}/${localTime.month} - ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";

              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc 20
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                  border: Border.all(color: kBorderCyan),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['Ten_benh_nhan'] ?? 'Bệnh nhân', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(timeStr, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("Triệu chứng: ${item['Trieu_chung'] ?? 'Không có'}", style: const TextStyle(color: kGreyTextColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Dịch vụ: ${item['Ten_dich_vu'] ?? 'Chưa rõ'}", style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleStatusAction(context, item['Ma_lich_hen'], 'reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // Bo 12
                            ),
                            child: const Text('Từ chối', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleStatusAction(context, item['Ma_lich_hen'], 'confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                            ),
                            child: const Text('Xác nhận', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAppointments(DoctorAppointmentViewModel vm) {
    if (vm.todayAppointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Text('Không có ca khám nào trong ngày hôm nay.', style: TextStyle(color: kGreyTextColor)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Khám Hôm Nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
              InkWell(
                onTap: () => onNavigate(1),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text('Xem tất cả', style: TextStyle(color: kPrimaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.todayAppointments.length,
            itemBuilder: (context, index) {
              final item = vm.todayAppointments[index];
              final localTime = DateTime.parse(item['Thoi_gian_Bdau']).toLocal();
              final timeStr = "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
              final isOnline = item['Hinh_thuc'] == 'online';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                  border: Border.all(color: kBorderCyan),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kLightCyanBg1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(timeStr, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['Ten_benh_nhan'] ?? 'Bệnh nhân', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(isOnline ? Icons.videocam : Icons.local_hospital, size: 14, color: kGreyTextColor),
                              const SizedBox(width: 4),
                              Text(item['Hinh_thuc'].toString().toUpperCase(), style: const TextStyle(color: kGreyTextColor, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.medical_services_outlined, size: 14, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item['Ten_dich_vu'] ?? 'Đang cập nhật', 
                                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void _handleStatusAction(BuildContext context, int appointmentId, String action) async {
    final result = await context.read<DoctorAppointmentViewModel>().updateStatus(appointmentId, action);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        )
      );
    }
  }
}

class _ExpandableRevenueCard extends StatefulWidget {
  final double totalRevenue;
  final List<dynamic> details;

  const _ExpandableRevenueCard({required this.totalRevenue, required this.details});

  @override
  State<_ExpandableRevenueCard> createState() => _ExpandableRevenueCardState();
}

class _ExpandableRevenueCardState extends State<_ExpandableRevenueCard> {
  bool _isExpanded = false;

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "0";
    return double.tryParse(amount.toString())?.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    ) ?? "0";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo 20
          boxShadow: [
            BoxShadow(color: kPrimaryColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                if (widget.details.isNotEmpty) {
                  setState(() => _isExpanded = !_isExpanded);
                }
              },
              borderRadius: BorderRadius.circular(kBorderRadiusLarge),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kDarkCyan], // 🌟 Đồng bộ dải màu Gradient chuẩn hệ thống
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: _isExpanded 
                      ? const BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))
                      : BorderRadius.circular(kBorderRadiusLarge),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Doanh thu hôm nay', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 5),
                          Text(
                            '${_formatCurrency(widget.totalRevenue)} VNĐ', 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                    if (widget.details.isNotEmpty)
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                        color: Colors.white, 
                        size: 30
                      ),
                  ],
                ),
              ),
            ),
            
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(kBorderRadiusLarge)),
                  border: Border.all(color: kBorderCyan),
                ),
                child: Column(
                  children: widget.details.map((item) {
                    final localTime = DateTime.parse(item['Thoi_gian_Bdau']).toLocal();
                    final timeStr = "${localTime.day}/${localTime.month} - ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['Ten_benh_nhan'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor)),
                                Text(timeStr, style: const TextStyle(color: kGreyTextColor, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['Ten_dich_vu'] ?? 'Khám dịch vụ',
                              style: const TextStyle(color: kTextColor, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_formatCurrency(item['Tong_tien'])} đ',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationBadge extends StatefulWidget{
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadge();
}

class _NotificationBadge extends State<NotificationBadge>{
  @override
  void initState() {
    context.read<NotificationViewmodel>().initSocket();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notificationVM = context.watch<NotificationViewmodel>();
    final unreadCount = notificationVM.notiUnRead;
    return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: kPrimaryColor,
                  size: 26,
                ),
              ),
            )
    );
  }
}