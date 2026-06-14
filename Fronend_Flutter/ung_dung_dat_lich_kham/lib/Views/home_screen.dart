import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/global_search_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/specialty_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/profile_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/health_record_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _maNguoiDung;
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserIdThenFetch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyViewModel>().loadAllSpecialties();
    });
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

  // Màu chủ đạo lấy cảm hứng từ ảnh thiết kế
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
              // 1. HEADER SECTION
              _buildHeader(),
              
              const SizedBox(height: 25),
              // 2. THỂ LOẠI SECTION
              _buildCategoryTitle(),
              const SizedBox(height: 15),
              _buildCategoryIcons(),
              
              const SizedBox(height: 25),
              // 3. LỊCH TRÌNH SẮP TỚI SECTION (Vùng Gradient Xanh)
              _buildUpcomingSchedule(),
              
              const SizedBox(height: 25),
              // 4. CHUYÊN KHOA SECTION
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

  // --- WIDGET THÀNH PHẦN ---

  // 1. Header bao gồm Nút chức năng bên trái và Avatar bên phải
  Widget _buildHeader() {
    final profileViewModel = context.watch<ProfileViewModel>();
    final user = profileViewModel.userProfile;

    // 🌟 Tạo một biến để chứa Widget hiển thị phần User bên phải
    Widget userSection;

    // Sử dụng if-else rõ ràng giúp Dart tự động hiểu user đã khác null (Type Promotion)
    if (profileViewModel.isLoading || user == null) {
      userSection = const CircularProgressIndicator();
    } else {
      userSection = Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Xin Chào', style: TextStyle(color: primaryCyan, fontSize: 13, fontWeight: FontWeight.w500)),
              // 🌟 ĐÃ SỬA: Xóa chữ const ở đầu Text, chỉ giữ const ở phần TextStyle cố định
              Text(
                user.fullName, 
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(width: 10),
          // 🌟 ĐÃ SỬA: Xóa chữ const ở đầu CircleAvatar vì NetworkImage chứa biến động
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
          // Nhóm Icon bên trái (Giữ nguyên)
          Row(
            children: [
              _buildHeaderIcon(Icons.notifications_none_outlined,(){}),
              const SizedBox(width: 10),
              _buildHeaderIcon(Icons.settings_outlined,(){}),
              const SizedBox(width: 10),
              _buildHeaderIcon(Icons.search, (){
                //if(!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => GlobalSearchScreen())
                );
              }),
            ],
          ),
          
          // Nhóm Thông tin User bên phải (Được truyền từ biến userSection đã xử lý logic ở trên)
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

  // 3. Khối Lịch trình sắp tới (Có gradient và lịch tuần)
  Widget _buildUpcomingSchedule() {
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
          // Tiêu đề Lịch trình
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch Trình Sắp Tới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Tháng 4', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 15,),

          Divider(
            color: Colors.white,
          ),

          const SizedBox(height: 15),
          
          // Slider lịch ngày trong tuần
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                _buildDayInWeek('9', 'T2', active: false),
                _buildDayInWeek('10', 'T3', active: false),
                _buildDayInWeek('11', 'T4', active: true), // Ngày đang chọn
                _buildDayInWeek('12', 'T5', active: false),
                _buildDayInWeek('13', 'T6', active: false),
                _buildDayInWeek('14', 'T7', active: false),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Khung chứa các ca hẹn chi tiết
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
                  child: Text('Xem tất cả', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                ),
                _buildAppointmentRow('11 Tháng 4 - Thứ 4', '10:00 am', 'Dr. Olivia Turner'),
                const Divider(color: Colors.white60, height: 20),
                _buildAppointmentRow('16 Tháng 4 - Thứ 2', '08:00 am', 'Dr. Alexander Bennett'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDayInWeek(String day, String dayName, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(color: active ? primaryCyan : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(dayName, style: TextStyle(color: active ? primaryCyan : Colors.white, fontSize: 11)),
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
                MaterialPageRoute(builder: (context) => SpecialtyListScreen())
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
      case 'tooth':
        return Icons.clean_hands_rounded; 
      case 'spa':
        return Icons.spa_rounded; 
      case 'visibility':
        return Icons.visibility_rounded; 
      case 'hearing':
        return Icons.hearing_rounded; 
      default:
        return Icons.local_hospital_rounded; 
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