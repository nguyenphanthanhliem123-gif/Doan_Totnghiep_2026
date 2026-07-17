import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:ung_dung_dat_lich_kham/Views/review_screen.dart';
import '../Constants/ui_constants.dart'; 
import '../viewmodels/appointment_viewmodel.dart';
import '../models/appointment_model.dart';
import 'appointment_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'reschedule_bottom_sheet.dart';
import '../utils/add_to_google_calendar_utils.dart';
import '../utils/appointment_action_helper.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  String _selectedStatus = 'all';
  DateTime? _selectedDate; 
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchData() {
    String dateParam = _selectedDate == null 
        ? 'all' 
        : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    
    context.read<AppointmentViewModel>().loadMyAppointments(
      status: _selectedStatus, 
      date: dateParam,
      search: _searchController.text.trim()
    );
  }

  String _getGeneralStatus(String status) {
    if (status == 'pending' || status == 'confirmed' || status == 'reschedule_pending') return 'upcoming';
    if (status == 'done') return 'completed';
    return 'cancelled'; // cho absent và cancelled
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<AppointmentViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2, 
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Lịch hẹn của tôi', style: kHeaderTextStyle), 
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm và lọc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 12), 
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
            child: Column(
              children: [
                // 1. Ô Tìm Kiếm
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo Tên Bác sĩ hoặc Mã đặt lịch...',
                    hintStyle: const TextStyle(color: kGreyTextColor, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    fillColor: kLightCyanBg1,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchData());
                  },
                ),
                const SizedBox(height: 10),
                
                // 2. Bộ Lọc Dropdown & DatePicker
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: kBorderCyan), borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                            style: const TextStyle(fontSize: 13, color: kTextColor, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text("Tất cả trạng thái")),
                              DropdownMenuItem(value: 'pending', child: Text("Chờ duyệt")),
                              DropdownMenuItem(value: 'confirmed', child: Text("Đang khám")),
                              DropdownMenuItem(value: 'reschedule_pending', child: Text("Chờ dời lịch")),
                              DropdownMenuItem(value: 'done', child: Text("Đã hoàn thành")),
                              DropdownMenuItem(value: 'cancelled', child: Text("Đã hủy")),
                              DropdownMenuItem(value: 'absent', child: Text("Vắng mặt")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                                _fetchData();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor)), child: child!),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _fetchData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(border: Border.all(color: kBorderCyan), borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null ? "Tất cả ngày" : "${_selectedDate!.day.toString().padLeft(2,'0')}/${_selectedDate!.month.toString().padLeft(2,'0')}/${_selectedDate!.year}",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedDate == null ? kTextColor : kPrimaryColor),
                              ),
                              Icon(Icons.calendar_month, color: _selectedDate == null ? kGreyTextColor : kPrimaryColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          setState(() => _selectedDate = null);
                          _fetchData();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                          child: const Icon(Icons.close, color: Colors.red, size: 18),
                        ),
                      )
                    ]
                  ],
                ),
              ],
            ),
          ),

          // Danh sách lịch hẹn
          Expanded(
            child: appVM.isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : appVM.allAppointments.isEmpty
                    ? const Center(child: Text('Không có lịch hẹn nào phù hợp.', style: TextStyle(color: kGreyTextColor, fontSize: 16)))
                    : RefreshIndicator(
                        color: kPrimaryColor,
                        onRefresh: () async => _fetchData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(kDefaultPadding), 
                          itemCount: appVM.allAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(appVM.allAppointments[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), 
        border: Border.all(color: kBorderCyan),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kBorderRadiusLarge),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointmentId: appointment.id)))
                .then((_) => _fetchData()); // Reload khi back lại
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: kLightCyanBg1,
                      backgroundImage: appointment.doctorAvatar != null && appointment.doctorAvatar!.startsWith('http')
                          ? NetworkImage(appointment.doctorAvatar!) 
                          : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                          const SizedBox(height: 4),
                          Text('Mã: ${appointment.bookingCode}', style: const TextStyle(fontSize: 12, color: kGreyTextColor)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(appointment.status), 
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: kBorderCyan),
                ),

                Text(
                  'Thời gian: ${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')} • ${appointment.startTime.day.toString().padLeft(2, '0')}/${appointment.startTime.month.toString().padLeft(2, '0')}/${appointment.startTime.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hình thức: ${appointment.type == "online" ? "Khám trực tuyến (Video Call)" : "Khám trực tiếp"}',
                  style: const TextStyle(fontSize: 14, color: kTextColor),
                ),

                const SizedBox(height: 16),
                _buildFooterButtons(context, appointment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String actualStatus) {
    Color bgColor; Color textColor; String text;

    switch (actualStatus) {
      case 'pending': bgColor = Colors.orange.shade50; textColor = Colors.orange; text = 'Chờ duyệt'; break;
      case 'confirmed': bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Đang khám'; break;
      case 'done': bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã hoàn thành'; break;
      case 'cancelled': bgColor = Colors.red.shade50; textColor = Colors.red; text = 'Đã hủy'; break;
      case 'reschedule_pending': bgColor = Colors.orange.shade50; textColor = Colors.orange.shade900; text = 'Chờ dời lịch'; break;
      case 'absent': bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; text = 'Vắng mặt'; break;
      default: bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; text = 'Không rõ'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFooterButtons(BuildContext context, AppointmentModel appointment) {
    String generalStatus = _getGeneralStatus(appointment.status);
    
    void navigateToDoctorDetail() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: appointment.doctorId)));
    }

    if (generalStatus == 'upcoming') {
      if (appointment.status == 'reschedule_pending') {
        return Row(
          children: [
            Expanded(
              child: AppointmentActionHelper.buildActionBtn(
                icon: Icons.edit_calendar, 
                text: appointment.doctorStatus == 'suspended' ? 'Bác sĩ khóa\n(Không thể dời)' : 'Xếp lại lịch\n(Bác sĩ báo bận)', 
                color: Colors.white, 
                bgColor: appointment.doctorStatus == 'suspended' ? Colors.grey : Colors.redAccent, 
                onTap: () {
                  if (appointment.doctorStatus == 'suspended') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bác sĩ này hiện đang tạm ngưng nhận bệnh nhân! Không thể dời lịch.'), backgroundColor: Colors.redAccent));
                    return;
                  }
                  showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => RescheduleBottomSheet(appointmentId: appointment.id, doctorId: appointment.doctorId));
                }
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppointmentActionHelper.buildActionBtn(
                icon: Icons.cancel_outlined, text: 'Hủy lịch hẹn\n(Không hoàn tiền)', 
                color: Colors.red, bgColor: Colors.red.shade50, 
                onTap: () {
                  AppointmentActionHelper.showPatientCancelDialog(
                    context: context, startTime: appointment.startTime, currentStatus: appointment.status,
                    onConfirm: () async {
                      final result = await context.read<AppointmentViewModel>().cancelAppointment(appointment.id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['succeeded'] ? Colors.green : Colors.red));
                    }
                  );
                }
              ),
            ),
          ],
        );
      }

      final now = DateTime.now();
      if (now.isAfter(appointment.endTime) && appointment.status == 'confirmed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
          alignment: Alignment.center,
          child: const Text("Đang chờ bác sĩ cập nhật kết quả", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
        );
      }

      return Row(
        children: [
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.refresh, 
              text: appointment.doctorStatus == 'suspended' ? 'Bác sĩ khóa' : 'Đổi lịch hẹn', 
              color: appointment.doctorStatus == 'suspended' ? Colors.grey : Colors.green, 
              bgColor: appointment.doctorStatus == 'suspended' ? Colors.grey.shade200 : Colors.green.shade50, 
              onTap: () {
                if (appointment.doctorStatus == 'suspended') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bác sĩ này hiện đang tạm ngưng nhận bệnh nhân! Không thể đổi lịch.'), backgroundColor: Colors.redAccent));
                  return;
                }
                final difference = appointment.startTime.difference(now);
                if (difference.inHours < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể đổi! Bạn chỉ được dời lịch trước giờ bắt đầu ít nhất 2 tiếng.'), backgroundColor: Colors.redAccent));
                  return;
                }
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => RescheduleBottomSheet(appointmentId: appointment.id, doctorId: appointment.doctorId));
              }
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.cancel_outlined, text: 'Hủy lịch hẹn', 
              color: Colors.red, bgColor: Colors.red.shade50, 
              onTap: () {
                AppointmentActionHelper.showPatientCancelDialog(
                  context: context, startTime: appointment.startTime, currentStatus: appointment.status,
                  onConfirm: () async {
                    final result = await context.read<AppointmentViewModel>().cancelAppointment(appointment.id);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['succeeded'] ? Colors.green : Colors.red));
                  }
                );
              }
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.calendar_month, text: 'Thêm vào\nCalendar', 
              color: Colors.grey.shade800, bgColor: Colors.grey.shade200, 
              onTap: () => CalendarUtils.addToCalendar(context, appointment)
            ),
          ),
        ],
      );
    } else if (generalStatus == 'completed') {
      return Row(
        children: [
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.replay, text: appointment.doctorStatus == 'suspended' ? 'Bác sĩ khóa' : 'Đặt lại lịch', 
              color: appointment.doctorStatus == 'suspended' ? Colors.grey : kPrimaryColor, bgColor: kLightCyanBg1, 
              onTap: () {
                if (appointment.doctorStatus == 'suspended') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bác sĩ này hiện đang tạm ngưng nhận bệnh nhân!'), backgroundColor: Colors.redAccent));
                } else navigateToDoctorDetail();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.star_border, text: 'Đánh giá', 
              color: Colors.white, bgColor: Colors.green, onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReviewScreen(appointmentId: appointment.id))); }
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.replay, text: appointment.doctorStatus == 'suspended' ? 'Bác sĩ khóa' : 'Đặt lại lịch', 
              color: Colors.white, bgColor: appointment.doctorStatus == 'suspended' ? Colors.grey : kPrimaryColor, 
              onTap: () {
                if (appointment.doctorStatus == 'suspended') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bác sĩ này hiện đang tạm ngưng nhận bệnh nhân!'), backgroundColor: Colors.redAccent));
                } else navigateToDoctorDetail();
              },
            ),
          ),
        ],
      );
    }
  }
}