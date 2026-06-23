import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor_appointment_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'doctor_appointment_screen.dart'; 

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({Key? key}) : super(key: key);

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  final Color primaryCyan = const Color(0xFF4BCBEB);

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
    // Tự động làm mới dữ liệu khi chuyển đổi qua lại giữa các Tab
    if (index == 0) {
      context.read<DoctorAppointmentViewModel>().loadDashboard();
    } else if (index == 1) {
      context.read<DoctorAppointmentViewModel>().loadDashboard();
    }
  }

  List<Widget> get _pages => [
    DoctorDashboardScreen(onNavigate: _onItemTapped), 
    const DoctorAppointmentScreen(),
    const Center(child: Text('Dịch Vụ Screen')), 
    const Center(child: Text('Cá Nhân Screen')), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: primaryCyan,
        unselectedItemColor: Colors.grey,
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

  final Color primaryCyan = const Color(0xFF4BCBEB);

  // 🌟 HÀM TIỆN ÍCH: Ngăn chặn tuyệt đối lỗi rỗng URL gây sập UI
  ImageProvider _safeAvatar(String? url) {
    if (url == null || url.trim().isEmpty || !url.startsWith('http')) {
      return const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png');
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorAppointmentViewModel>();

    return SafeArea(
      child: doctorVM.isLoading && doctorVM.pendingAppointments.isEmpty
        ? Center(child: CircularProgressIndicator(color: primaryCyan))
        : RefreshIndicator(
            onRefresh: () async {
              await context.read<DoctorAppointmentViewModel>().loadDashboard();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  _buildHeader(context, doctorVM),
                  const SizedBox(height: 20),
                  _buildQuickStats(doctorVM),
                  const SizedBox(height: 20),
                  // 🌟 GỌI WIDGET CARD DOANH THU XỔ XUỐNG Ở ĐÂY
                  _ExpandableRevenueCard(
                    totalRevenue: doctorVM.todayRevenue, 
                    details: doctorVM.revenueDetails
                  ),
                  const SizedBox(height: 25),
                  _buildPendingAppointments(context, doctorVM),
                  const SizedBox(height: 25),
                  _buildTodayAppointments(doctorVM),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  // Cập nhật Header: Thêm Công tắc Bật/Bận
  Widget _buildHeader(BuildContext context, DoctorAppointmentViewModel doctorVM) {
    final profileVM = context.watch<ProfileViewModel>();
    final user = profileVM.userProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryCyan.withOpacity(0.2),
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
                  style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Giao diện Công tắc Bật/Tắt trạng thái Bác sĩ
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: doctorVM.isDoctorActive,
                activeColor: primaryCyan,
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
                offset: const Offset(0, -5), // Kéo Text lên sát lại cho đẹp
                child: Text(
                  doctorVM.isDoctorActive ? 'Sẵn sàng' : 'Đang bận', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: doctorVM.isDoctorActive ? primaryCyan : Colors.redAccent
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildStatCard('Ca chờ duyệt', vm.pendingCount.toString(), Icons.pending_actions, Colors.orange),
          const SizedBox(width: 10),
          _buildStatCard('Khám hôm nay', vm.todayCount.toString(), Icons.event_available, primaryCyan),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAppointments(BuildContext context, DoctorAppointmentViewModel vm) {
    if (vm.pendingAppointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Text('Không có lịch chờ xác nhận mới.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('Lịch Chờ Xác Nhận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(timeStr, style: TextStyle(color: primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("Triệu chứng: ${item['Trieu_chung'] ?? 'Không có'}", style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("Dịch vụ: ${item['Ten_dich_vu'] ?? 'Chưa rõ'}", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Từ chối', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleStatusAction(context, item['Ma_lich_hen'], 'confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryCyan,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Xác nhận', style: TextStyle(fontSize: 13)),
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
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Text('Không có ca khám nào trong ngày hôm nay.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Khám Hôm Nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => onNavigate(1),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text('Xem tất cả', style: TextStyle(color: primaryCyan, fontSize: 13, fontWeight: FontWeight.w600)),
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
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(timeStr, style: TextStyle(color: primaryCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['Ten_benh_nhan'] ?? 'Bệnh nhân', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(isOnline ? Icons.videocam : Icons.local_hospital, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(item['Hinh_thuc'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16, color: primaryCyan),
                      onPressed: () {},
                    )
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


// Widget Card doanh thu xổ xuống
class _ExpandableRevenueCard extends StatefulWidget {
  final double totalRevenue;
  final List<dynamic> details;

  const _ExpandableRevenueCard({required this.totalRevenue, required this.details});

  @override
  State<_ExpandableRevenueCard> createState() => _ExpandableRevenueCardState();
}

class _ExpandableRevenueCardState extends State<_ExpandableRevenueCard> {
  bool _isExpanded = false; // Biến kiểm soát đóng/mở

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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4BCBEB).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            // 1. Phần Header (Luôn hiển thị)
            InkWell(
              onTap: () {
                if (widget.details.isNotEmpty) {
                  setState(() => _isExpanded = !_isExpanded);
                }
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4BCBEB), Color(0xFF2E9BB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: _isExpanded 
                      ? const BorderRadius.vertical(top: Radius.circular(15)) // Mở ra thì chỉ bo góc trên
                      : BorderRadius.circular(15), // Đóng lại thì bo tròn hết
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
            
            // 2. Phần danh sách chi tiết tiền khám (Animation xổ xuống)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity), // Khung rỗng khi Đóng
              secondChild: Container( // Nội dung khi Mở
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  border: Border.all(color: Colors.grey.shade200),
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
                          // Cột 1: Tên & Giờ
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['Ten_benh_nhan'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          // Cột 2: Tên Dịch Vụ
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['Ten_dich_vu'] ?? 'Khám dịch vụ',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              maxLines: 1, // 🌟 Ép chỉ hiển thị 1 dòng
                              overflow: TextOverflow.ellipsis, // 🌟 Cắt bớt và hiện ...
                            ),
                          ),
                          // Cột 3: Số tiền
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_formatCurrency(item['Tong_tien'])} đ',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300), // Tốc độ animation xổ xuống
            ),
          ],
        ),
      ),
    );
  }
}