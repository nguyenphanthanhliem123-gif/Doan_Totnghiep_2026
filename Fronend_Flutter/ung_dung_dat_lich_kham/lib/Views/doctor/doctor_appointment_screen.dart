import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../Constants/ui_constants.dart'; 
import '../../viewmodels/doctor_appointment_list_viewmodel.dart';
import 'doctor_appointment_detail_screen.dart';
import '../../utils/appointment_action_helper.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  State<DoctorAppointmentScreen> createState() => _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen> {
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
    
    context.read<DoctorAppointmentListViewModel>().loadAllAppointments(
      status: _selectedStatus, 
      date: dateParam,
      search: _searchController.text.trim()
    );
  }

  ImageProvider _safeAvatar(String? url) {
    if (url == null || url.trim().isEmpty || !url.startsWith('http')) {
      return const NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png');
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorAppointmentListViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2, 
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Quản lý Lịch hẹn', style: kHeaderTextStyle), 
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
                    hintText: 'Tìm theo Tên Bệnh nhân hoặc Mã đặt lịch...',
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

                // 2. Bộ lọc Dropdown & DatePicker
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
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : vm.appointments.isEmpty
                    ? const Center(child: Text('Không tìm thấy lịch hẹn nào phù hợp.', style: TextStyle(color: kGreyTextColor, fontSize: 16)))
                    : RefreshIndicator(
                        color: kPrimaryColor,
                        onRefresh: () async => _fetchData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(kDefaultPadding), 
                          itemCount: vm.appointments.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(context, vm.appointments[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // (Phần _buildAppointmentCard và phần dưới giữ nguyên y hệt như cũ)
  // ...
  Widget _buildAppointmentCard(BuildContext context, dynamic appointment) {
    final status = appointment['Trang_thai_lich_hen'] ?? 'pending';
    final localStart = DateTime.parse(appointment['Thoi_gian_Bdau']).toLocal();
    final localEnd = DateTime.parse(appointment['Thoi_gian_Kthuc']).toLocal();
    
    final timeStr = "${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')} - ${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}";
    final dateStr = "${localStart.day.toString().padLeft(2, '0')}/${localStart.month.toString().padLeft(2, '0')}/${localStart.year}";

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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorAppointmentDetailScreen(appointmentId: appointment['Ma_lich_hen'])),
            );
            _fetchData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: kLightCyanBg1,
                      backgroundImage: _safeAvatar(appointment['Anh_benh_nhan']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment['Ten_benh_nhan'] ?? 'Bệnh nhân', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                          const SizedBox(height: 4),
                          Text('Mã đặt lịch: ${appointment['Ma_booking']}', style: const TextStyle(fontSize: 12, color: kGreyTextColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildStatusBadge(status), 
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: kBorderCyan),
                ),
                Text('Thời gian: $timeStr • $dateStr', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor)),
                const SizedBox(height: 8),
                Text('Hình thức: ${appointment['Hinh_thuc'] == "online" ? "Khám trực tuyến (Video Call)" : "Khám trực tiếp tại phòng khám"}', style: const TextStyle(fontSize: 14, color: kTextColor)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dịch vụ: ', style: TextStyle(fontSize: 14, color: kTextColor)),
                    Expanded(child: Text('${appointment['Ten_dich_vu'] ?? 'Đang cập nhật'}', style: const TextStyle(fontSize: 14, color: kTextColor, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFooterButtons(context, appointment, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor; Color textColor; String text;
    switch (status) {
      case 'pending': bgColor = Colors.orange.shade50; textColor = Colors.orange; text = 'Chờ duyệt'; break;
      case 'confirmed': bgColor = Colors.blue.shade50; textColor = Colors.blue; text = 'Đang khám'; break;
      case 'done': bgColor = Colors.green.shade50; textColor = Colors.green; text = 'Đã hoàn thành'; break;
      case 'cancelled': bgColor = Colors.red.shade50; textColor = Colors.red; text = 'Đã hủy'; break;
      case 'reschedule_pending': bgColor = Colors.orange.shade50; textColor = Colors.orange.shade900; text = 'Chờ dời lịch'; break;
      case 'absent': default: bgColor = Colors.grey.shade200; textColor = Colors.grey.shade700; text = 'Vắng mặt'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFooterButtons(BuildContext context, dynamic appointment, String status) {
    final vm = context.read<DoctorAppointmentListViewModel>();
    final int appointmentId = appointment['Ma_lich_hen'];
    
    // Check Giờ kết thúc
    final endTime = DateTime.parse(appointment['Thoi_gian_Kthuc']).toLocal();
    final isPastEnd = DateTime.now().isAfter(endTime);

    void handleAction(String action) async {
      final res = await vm.updateStatus(appointmentId, action, status: _selectedStatus, date: _selectedDate == null ? 'all' : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
    }

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(child: AppointmentActionHelper.buildActionBtn(icon: Icons.cancel_outlined, text: 'Từ chối', color: Colors.red, bgColor: Colors.red.shade50, onTap: () => handleAction('reject'))),
          const SizedBox(width: 8),
          Expanded(child: AppointmentActionHelper.buildActionBtn(icon: Icons.check_circle_outline, text: 'Xác nhận', color: Colors.white, bgColor: kPrimaryColor, onTap: () => handleAction('confirm'))),
        ],
      );
    } else if (status == 'confirmed') {
      return Row(
        children: [
          if (!isPastEnd) ...[
            Expanded(child: AppointmentActionHelper.buildActionBtn(
              icon: Icons.event_busy, text: 'Báo bận', color: Colors.red, bgColor: Colors.red.shade50, 
              onTap: () => AppointmentActionHelper.showDoctorCancelDialog(
                context: context, 
                onConfirm: () async {
                  final res = await vm.updateStatus(appointmentId, 'reject', status: _selectedStatus, date: _selectedDate == null ? 'all' : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}");
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red));
                }
              )
            )),
            const SizedBox(width: 8),
          ],
          Expanded(child: AppointmentActionHelper.buildActionBtn(
            icon: Icons.person_off_outlined, text: 'Báo vắng', color: Colors.orange, bgColor: Colors.orange.shade50, 
            onTap: () {
              final startTime = DateTime.parse(appointment['Thoi_gian_Bdau']).toLocal();
              if (DateTime.now().isAfter(startTime.add(const Duration(minutes: 15)))) {
                vm.updateStatusAbsent(appointmentId, status: _selectedStatus, date: _selectedDate == null ? 'all' : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}")
                  .then((res) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red)); });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ báo vắng khi giờ khám qua tối thiểu 15 phút!'), backgroundColor: Colors.orange));
              }
            }
          )),
          const SizedBox(width: 8),
          Expanded(child: AppointmentActionHelper.buildActionBtn(icon: Icons.edit_document, text: 'Kê đơn', color: Colors.white, bgColor: kPrimaryColor, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorAppointmentDetailScreen(appointmentId: appointmentId))).then((_) => _fetchData());
          })),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: AppointmentActionHelper.buildActionBtn(icon: Icons.visibility, text: 'Xem hồ sơ & Đơn thuốc', color: kPrimaryColor, bgColor: kLightCyanBg1, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorAppointmentDetailScreen(appointmentId: appointmentId))).then((_) => _fetchData());
          })),
        ],
      );
    }
  }
}