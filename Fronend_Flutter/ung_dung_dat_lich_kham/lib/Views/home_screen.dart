import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/global_search_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/notification_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/specialty_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';
// Đã thay thế Schedule bằng Appointment
import 'package:ung_dung_dat_lich_kham/viewmodels/appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/health_record_menu_screen.dart';
import 'package:ung_dung_dat_lich_kham/views/appointment_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/notification_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/chatbot_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _maNguoiDung;
  bool _isLoading = false;

  // BIẾN TRẠNG THÁI CHO LỊCH TRÌNH 7 NGÀY
  DateTime _selectedDate = DateTime.now(); 
  List<DateTime> _next7Days = [];          
  
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
    
    // Tự động tạo danh sách 7 ngày tới
    _generateNext7Days();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyViewModel>().loadAllSpecialties();
      context.read<NotificationViewmodel>().initSocket();
      _scrollToSelectedDate(animate: false);
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _generateNext7Days() {
    final now = DateTime.now();
    setState(() {
      _next7Days = List.generate(7, (index) => now.add(Duration(days: index)));
      _selectedDate = _next7Days.first; // Mặc định chọn ngày hôm nay
    });
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_calendarScrollController.hasClients) return;
    
    int index = _next7Days.indexWhere((d) => 
      d.day == _selectedDate.day && 
      d.month == _selectedDate.month && 
      d.year == _selectedDate.year
    );

    if (index != -1) {
      double itemWidth = 62.0;
      double offset = (index * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2) + 20; 
      
      if (offset < 0) offset = 0;
      final maxScroll = _calendarScrollController.position.maxScrollExtent;
      if (offset > maxScroll) offset = maxScroll;

      if (animate) {
        _calendarScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _calendarScrollController.jumpTo(offset);
      }
    }
  }

  

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      case DateTime.sunday: return 'CN';
      default: return '';
    }
  }

  String getShortName(String fullName) {
    if (fullName.isEmpty) return "";
    List<String> parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return "${parts[parts.length - 2]} ${parts.last}";
    }
    return fullName;
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false).getSavedUserId();

    if (!mounted) return;

    setState(() {
      _maNguoiDung = id;
    });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
        
        // GỌI API LẤY LỊCH CÁ NHÂN NGAY KHI VỪA VÀO HOME
        if (mounted) {
          await context.read<AppointmentViewModel>().loadMyAppointments();
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final Color primaryCyan = kPrimaryColor;
  final Color darkCyan = const Color(0xFF00A8B5);

  @override
  Widget build(BuildContext context) {
    final specialtyVM = context.watch<SpecialtyViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _buildHeader(),
              const SizedBox(height: 25),
              _buildCategoryTitle(),
              const SizedBox(height: 15),
              _buildCategoryIcons(),
              const SizedBox(height: 25),
              // 3. LỊCH TRÌNH SẮP TỚI CỦA BỆNH NHÂN
              _buildUpcomingSchedule(),
              const SizedBox(height: 25),
              _buildSpecialtyHeader(),
              const SizedBox(height: 15),
              _buildSpecialtyGrid(specialtyVM),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    Widget userSection;

    if (profileViewModel.isLoading || user == null) {
      userSection = const CircularProgressIndicator();
    } else {
      userSection = Row(
        mainAxisAlignment: MainAxisAlignment.end, // Căn các phần tử sang sát lề phải
        children: [
          Flexible( // 1. Bọc Flexible để giới hạn chiều rộng của Column
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xin Chào', 
                  style: TextStyle(color: primaryCyan, fontSize: 13, fontWeight: FontWeight.w500)
                ),
                Text(
                  getShortName(user.fullName), // Kết quả sẽ là "Thanh Liêm"
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            backgroundImage: NetworkImage(
              user.avatar ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
            ),
          )
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildHeaderIcon(Icons.notifications_none_outlined,(){
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => NotificationScreen())
                );
              }),
              const SizedBox(width: 10),
              _buildHeaderIcon(Icons.search, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => GlobalSearchScreen())
                );
              }),
            ],
          ),
          const SizedBox(width: 20), // Tạo khoảng cách tối thiểu giữa cụm Icon trái và cụm User phải
          Expanded(child: userSection), // 4. Bọc Expanded để báo cho Flutter biết userSection chỉ được phép chiếm phần không gian còn lại
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    final notificationVM = context.watch<NotificationViewmodel>();
    
    // 1. Kiểm tra xem icon hiện tại có phải là nút thông báo hay không
    final isNotification = icon == Icons.notifications_none_outlined;
    
    // 2. Lấy số lượng thông báo chưa đọc từ ViewModel (thay 'unreadCount' bằng biến thực tế của bạn nếu khác tên)
    final unreadCount = notificationVM.notiUnRead; 

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FA),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0F2F4), width: 1),
      ),
      child: IconButton(
        // 3. Nếu là nút thông báo thì bọc Icon trong widget Badge chính chủ của Flutter
        icon: isNotification
            ? Badge(
                isLabelVisible: unreadCount > 0, // Chỉ hiện badge khi có thông báo > 0
                label: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: Icon(icon, color: primaryCyan, size: 22),
              )
            : Icon(icon, color: primaryCyan, size: 22),
        onPressed: onTap,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        'Thể Loại',
        style: TextStyle(color: primaryCyan, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        // Dùng MainAxisAlignment.start để các icon xếp từ trái qua, cách đều nhau bằng SizedBox
        mainAxisAlignment: MainAxisAlignment.start, 
        children: [
          InkWell(
            child: _buildCategoryItem('Hồ Sơ', Icons.assignment_outlined),
            onTap: () {
              if(!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HealthRecordListScreen())
              );
            },
          ),
          const SizedBox(width: 30),
          InkWell(
            child: _buildCategoryItem('Chuyên Khoa', Icons.local_hospital_outlined),
            onTap: () {
              if(!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SpecialtyListScreen())
              );
            },
          ),
          const SizedBox(width: 30),
          
          // THÊM LUỒNG QUA TRANG CHAT AI Ở ĐÂY
          InkWell(
            child: _buildCategoryItem('Trợ lý AI', Icons.support_agent_outlined), // Icon robot tư vấn
            onTap: () {
              if(!mounted) return;
              // Điều hướng sang màn hình Chat đã thiết kế
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatbotScreen())
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryCyan, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(color: primaryCyan, fontSize: 12, fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  Widget _buildUpcomingSchedule() {
    // Lấy data từ ViewModel lịch hẹn
    final appointmentVM = context.watch<AppointmentViewModel>();

    // Lọc ra các lịch sắp tới (pending/confirmed/reschedule_pending) trùng với ngày đang chọn
    final filteredAppointments = appointmentVM.allAppointments.where((app) {
      final isUpcomingStatus = app.status == 'pending' || app.status == 'confirmed' || app.status == 'reschedule_pending';
      final isSameDate = app.startTime.year == _selectedDate.year && 
                         app.startTime.month == _selectedDate.month && 
                         app.startTime.day == _selectedDate.day;
      
      return isUpcomingStatus && isSameDate;
    }).toList();
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimaryColor, kDarkCyan], // Dùng đúng biến màu chuẩn của hẹ thống bạn
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Lịch Trình Sắp Tới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // Thanh cuộn 7 ngày
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              height: 65,
              child: ListView.builder(
                controller: _calendarScrollController, 
                scrollDirection: Axis.horizontal,
                itemCount: _next7Days.length,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemBuilder: (context, index) {
                  final DateTime dayData = _next7Days[index];
                  final bool isSelected = dayData.day == _selectedDate.day &&
                                          dayData.month == _selectedDate.month &&
                                          dayData.year == _selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = dayData;
                      });
                      _scrollToSelectedDate();
                    },
                    child: _buildDayInWeek(
                      dayData.day.toString(),
                      index == 0 ? "Hôm nay" : _getWeekdayName(dayData.weekday),
                      active: isSelected,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Khung hiển thị chi tiết lịch hẹn
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () {
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AppointmentScreen()
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Xem tất cả', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Hiển thị trạng thái Loading
                if (appointmentVM.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                // Hiển thị Lỗi nếu có
                else if (appointmentVM.errorMessage.isNotEmpty && appointmentVM.allAppointments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(appointmentVM.errorMessage, style: const TextStyle(color: Colors.redAccent)),
                  )
                // Hiển thị thông báo trống
                else if (filteredAppointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Bạn không có lịch khám nào trong ngày này', style: TextStyle(color: Colors.white70)),
                  )
                // Render List lịch hẹn sau khi lọc
                else
                  ...filteredAppointments.take(5).map((app) {
                    String timeStr = "${app.startTime.hour.toString().padLeft(2, '0')}:${app.startTime.minute.toString().padLeft(2, '0')}";

                    return Column(
                      children: [
                        _buildAppointmentRow(
                          'Ngày ${_selectedDate.day} Th. ${_selectedDate.month}', 
                          timeStr, 
                          app.doctorName
                        ),
                        const Divider(color: Colors.white60, height: 20),
                      ],
                    );
                  }).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDayInWeek(String day, String dayName, {required bool active}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: active ? null : Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: TextStyle(color: active ? primaryCyan : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(dayName, style: TextStyle(color: active ? primaryCyan : Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(String date, String time, String doctorName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(time, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  Text(doctorName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSpecialtyHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Chuyên khoa', style: TextStyle(color: primaryCyan, fontSize: 18, fontWeight: FontWeight.bold)),
          InkWell(
            child: Text('Xem tất cả', style: TextStyle(color: primaryCyan, fontSize: 13)),
            onTap: (){
              if(!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SpecialtyListScreen())
              );
            },
          )
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
      switch (iconName) {
        case 'tooth': return Icons.clean_hands_rounded; 
        case 'spa': return Icons.spa_rounded; 
        case 'visibility': return Icons.visibility_rounded; 
        case 'hearing': return Icons.hearing_rounded; 
        default: return Icons.local_hospital_rounded; 
      }
    }

  Widget _buildSpecialtyGrid(SpecialtyViewModel specialtyVM) {
    if (specialtyVM.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }
    if (specialtyVM.listSpecialty == null || specialtyVM.listSpecialty!.isEmpty) {
      return const Center(child: Text("Không có dữ liệu chuyên khoa", style: TextStyle(color: Colors.grey)));
    }

    // Giới hạn chỉ lấy tối đa 6 chuyên khoa như yêu cầu
    final displaySpecialties = specialtyVM.listSpecialty!;

    return SizedBox(
      height: 105, // Cố định chiều cao vừa vặn cho item cuộn ngang
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Chuyển thành cuộn ngang giống ảnh mẫu
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displaySpecialties.length,
        itemBuilder: (context, index) {
          final specialties = displaySpecialties[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Khoảng cách giữa các item
            child: InkWell(
              onTap: () {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DoctorListScreen(
                      specialtyId: specialties.id,
                      specialtyName: specialties.name,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 85, // Cố định độ rộng của mỗi ô chuyên khoa
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Icon bọc trong vòng tròn nền màu nhạt giống hệt ảnh mẫu
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1), // Màu nền Cyan nhạt
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(specialties.image), 
                        color: kPrimaryColor, // Icon màu Cyan đậm chủ đạo
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8), // Khoảng cách giữa icon và chữ
                    // Chữ hiển thị tên chuyên khoa
                    Text(
                      specialties.name,
                      textAlign: TextAlign.center,
                      maxLines: 2, // Tối đa 2 dòng để không bị lỗi giao diện
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w500, // Độ đậm vừa phải thanh lịch
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}