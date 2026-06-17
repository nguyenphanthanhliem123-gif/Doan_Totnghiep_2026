import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/ViewModels/schedule_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/global_search_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/specialty_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/health_record_menu_screen.dart';
import 'package:ung_dung_dat_lich_kham/views/appointment_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _maNguoiDung;
  bool _isLoading = false;

  // BIẾN TRẠNG THÁI CHO LỊCH TRÌNH ĐỘNG
  DateTime _selectedDate = DateTime.now(); // Ngày đang được chọn
  List<DateTime> _daysInMonth = [];        // Danh sách các ngày trong tháng hiện tại
  
  // 🌟 THÊM SCROLL CONTROLLER ĐỂ ĐIỀU KHIỂN VUỐT/CUỘN TỰ ĐỘNG
  final ScrollController _calendarScrollController = ScrollController();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserIdThenFetch();
    
    // Tự động tạo danh sách ngày của tháng hiện tại khi mở app
    _generateDaysForMonth(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyViewModel>().loadAllSpecialties();
      // Cuộn đến ngày hiện tại khi vừa mở màn hình lên
      _scrollToSelectedDate(animate: false);
      _fetchSchedulesDebounced();
    });
  }

  @override
  void dispose() {
    // 🌟 GIẢI PHÓNG BỘ NHỚ SCROLL CONTROLLER
    _calendarScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _fetchSchedulesDebounced() {
    // Nếu có một Timer đang chạy (do người dùng vừa bấm trước đó vài mili-giây), hủy nó đi
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Đặt Timer mới: Sau đúng 500 mili-giây (0.5s) không ai bấm nữa thì mới chạy code bên trong
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Định dạng ngày thành chuẩn YYYY-MM-DD để gửi lên API
      String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      
      // Gọi API lấy dữ liệu lịch trình
      context.read<ScheduleViewModel>().loadDoctorSchedules(formattedDate);
    });
  }

  // Hàm tính toán tất cả các ngày trong một tháng cụ thể
  void _generateDaysForMonth(DateTime date) {
    final int totalDays = DateTime(date.year, date.month + 1, 0).day;
    
    setState(() {
      _daysInMonth = List.generate(
        totalDays,
        (index) => DateTime(date.year, date.month, index + 1),
      );
    });
  }

  // 🌟 HÀM TỰ ĐỘNG CUỘN ĐẾN NGÀY ĐANG ĐƯỢC CHỌN
  void _scrollToSelectedDate({bool animate = true}) {
    if (!_calendarScrollController.hasClients) return;
    
    // Tìm vị trí index của ngày đang chọn trong danh sách tháng
    int index = _daysInMonth.indexWhere((d) => 
      d.day == _selectedDate.day && 
      d.month == _selectedDate.month && 
      d.year == _selectedDate.year
    );

    if (index != -1) {
      // Giả định mỗi Item ngày rộng khoảng 62px (bao gồm cả margin ngang)
      double itemWidth = 62.0;
      // Tính toán vị trí offset để ngày được chọn nằm gần giữa thanh cuộn
      double offset = (index * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2) + 40;
      
      // Khống chế offset không vượt quá giới hạn cuộn
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

  // 🌟 HÀM XỬ LÝ KHI BẤM MŨI TÊN TRÁI (LÙI 1 NGÀY)
  void _navigateToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    final bool isDifferentMonth = previousDay.month != _selectedDate.month || previousDay.year != _selectedDate.year;
    
    setState(() {
      _selectedDate = previousDay;
    });

    if (isDifferentMonth) {
      _generateDaysForMonth(previousDay);
    }
    
    // Đợi UI render xong thì cuộn theo ngày mới
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());

    _fetchSchedulesDebounced();
  }

  // 🌟 HÀM XỬ LÝ KHI BẤM MŨI TÊN PHẢI (TIẾN 1 NGÀY)
  void _navigateToNextDay() {
    final nextDay = _selectedDate.add(const Duration(days: 1));
    final bool isDifferentMonth = nextDay.month != _selectedDate.month || nextDay.year != _selectedDate.year;
    
    setState(() {
      _selectedDate = nextDay;
    });

    if (isDifferentMonth) {
      _generateDaysForMonth(nextDay);
    }

    // Đợi UI render xong thì cuộn theo ngày mới
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());

    _fetchSchedulesDebounced();
  }

  // Hàm chuyển đổi thứ sang chuỗi tiếng Việt
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

  // Hàm mở bộ chọn Tháng / Năm
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'CHỌN THÁNG XEM LỊCH TRÌNH',
    );
    if (picked != null && (picked.month != _selectedDate.month || picked.year != _selectedDate.year)) {
      setState(() {
        _selectedDate = picked;
      });
      _generateDaysForMonth(picked);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate(animate: false));

      _fetchSchedulesDebounced();
    }
  }

  Future<void> _loadUserIdThenFetch() async {
    final id = await Provider.of<AuthViewModel>(context, listen: false)
        .getSavedUserId();

    if (!mounted) return;

    setState(() {
      _maNguoiDung = id;
    });

    if (id != null) {
      final maNguoiDung = int.tryParse(id);
      if (maNguoiDung != null) {
        await context.read<ProfileViewModel>().getUserProfile(maNguoiDung);
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
              // 3. LỊCH TRÌNH SẮP TỚI SECTION
              _buildUpcomingSchedule(),
              const SizedBox(height: 25),
              _buildSpecialtyHeader(),
              const SizedBox(height: 15),
              _buildSpecialtyGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header bao gồm Nút chức năng bên trái và Avatar bên phải
  Widget _buildHeader() {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    Widget userSection;

    if (profileViewModel.isLoading || user == null) {
      userSection = const CircularProgressIndicator();
    } else {
      userSection = Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Xin Chào', style: TextStyle(color: primaryCyan, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                user.fullName, 
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ],
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
              _buildHeaderIcon(Icons.notifications_none_outlined,(){}),
              const SizedBox(width: 10),
              _buildHeaderIcon(Icons.settings_outlined,(){}),
              const SizedBox(width: 10),
              _buildHeaderIcon(Icons.search, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => GlobalSearchScreen())
                );
              }),
            ],
          ),
          userSection,
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FA),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0F2F4), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: primaryCyan, size: 22),
        onPressed: onTap,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  // 2. Thể loại
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

  // 3. Khối Lịch trình sắp tới (Có Mũi tên 2 bên & Tự động cuộn theo ngày)
  Widget _buildUpcomingSchedule() {
    final scheduleVM = context.watch<ScheduleViewModel>();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryCyan, darkCyan],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Tiêu đề Lịch trình & Nút bấm chọn Tháng bên phải
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch Trình Sắp Tới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () => _selectMonth(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tháng ${_selectedDate.month}/${_selectedDate.year}', 
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white,)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          const Divider(color: Colors.white54),
          const SizedBox(height: 5),
          
          // 🌟 KHỐI ĐIỀU HƯỚNG NGÀY: Bao gồm Mũi tên trái - Thanh cuộn giữa - Mũi tên phải
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                // 1. Mũi tên lùi ngày bên trái
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: _navigateToPreviousDay,
                ),
                
                // 2. Danh sách ngày cuộn ở giữa
                Expanded(
                  child: SizedBox(
                    height: 65,
                    child: ListView.builder(
                      controller: _calendarScrollController, // Gắn bộ điều khiển cuộn vào đây
                      scrollDirection: Axis.horizontal,
                      itemCount: _daysInMonth.length,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemBuilder: (context, index) {
                        final DateTime dayData = _daysInMonth[index];
                        final bool isSelected = dayData.day == _selectedDate.day &&
                                                dayData.month == _selectedDate.month &&
                                                dayData.year == _selectedDate.year;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = dayData;
                            });
                            _scrollToSelectedDate();

                            _fetchSchedulesDebounced();
                          },
                          child: _buildDayInWeek(
                            dayData.day.toString(),
                            _getWeekdayName(dayData.weekday),
                            active: isSelected,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // 3. Mũi tên tiến ngày bên phải
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  onPressed: _navigateToNextDay,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Khung chứa các ca hẹn chi tiết theo ngày được chọn
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

                // Hiển thị Loading khi đang gọi API
                if (scheduleVM.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                // Hiển thị Lỗi nếu có
                else if (scheduleVM.errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(scheduleVM.errorMessage, style: const TextStyle(color: Colors.redAccent)),
                  )
                // Hiển thị thông báo trống nếu không có lịch
                else if (scheduleVM.schedules == null || scheduleVM.schedules!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Không có lịch khám nào trong ngày này', style: TextStyle(color: Colors.white70)),
                  )
                // Hiển thị danh sách nếu có data
                else
                  ...scheduleVM.schedules!.take(5).map((schedule) {
                    // 🌟 Hàm take(5) giúp cắt mảng chỉ lấy tối đa 5 phần tử đầu tiên
                    
                    // Format thời gian hiển thị, ví dụ "08:00"
                    String timeStr = "";
                    if (schedule.thoiGianBdau != null) {
                      timeStr = "${schedule.thoiGianBdau!.hour.toString().padLeft(2, '0')}:${schedule.thoiGianBdau!.minute.toString().padLeft(2, '0')}";
                    }

                    return Column(
                      children: [
                        _buildAppointmentRow(
                          'Ngày ${_selectedDate.day} Th. ${_selectedDate.month}', 
                          timeStr, 
                          schedule.tenNguoiDung ?? 'Bác sĩ ẩn danh'
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

  // 4. Chuyên khoa
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

  Widget _buildSpecialtyGrid() {
    final specialtyVM = context.watch<SpecialtyViewModel>();

    IconData _getIconData(String? iconName) {
      switch (iconName) {
        case 'tooth': return Icons.clean_hands_rounded; 
        case 'spa': return Icons.spa_rounded; 
        case 'visibility': return Icons.visibility_rounded; 
        case 'hearing': return Icons.hearing_rounded; 
        default: return Icons.local_hospital_rounded; 
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: specialtyVM.isLoading
        ? const Center(child: CircularProgressIndicator(),)
        : specialtyVM.errorMessage.isNotEmpty
          ? Center(child: Text(specialtyVM.errorMessage, style: const TextStyle(color: Colors.red)))
          : specialtyVM.listSpecialty == null || specialtyVM.listSpecialty!.isEmpty
            ? const Center(child: Text('Không tìm thấy chuyên khoa nào.'))
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: specialtyVM.listSpecialty!.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final specialties = specialtyVM.listSpecialty![index];
            return InkWell(
              onTap: () {
                if(!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DoctorListScreen(specialtyId: specialties.id, specialtyName: specialties.name,))
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: primaryCyan,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getIconData(specialties.image), color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        specialties.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );
  }
}