import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Constants/ui_constants.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../viewmodels/appointment_viewmodel.dart';
import '../models/doctor_detail_model.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final int appointmentId;
  final int doctorId;

  const RescheduleBottomSheet({super.key, required this.appointmentId, required this.doctorId});

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  int? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu lịch trống của bác sĩ này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().fetchDoctorDetail(widget.doctorId);
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();
    final doctor = doctorVM.doctorDetail;

    if (doctorVM.isLoading || doctor == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    // Logic lọc slot y hệt BookingScreen
    List<String> availableDateStrings = doctor.schedules.map((s) => s.date).toList();
    List<DoctorTimeSlotModel> activeSlots = [];
    if (_selectedDate != null) {
      String selectedDateStr = _formatDate(_selectedDate!);
      final scheduleForDay = doctor.schedules.firstWhere(
        (s) => s.date == selectedDateStr,
        orElse: () => DoctorScheduleModel(date: '', slots: []),
      );
      activeSlots = scheduleForDay.slots;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      // ✅ FIX LỖI Ở ĐÂY: Bọc toàn bộ Column vào SingleChildScrollView để chống lỗi tràn viền khi resize cửa sổ.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tự co giãn theo nội dung
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Center(child: Text("Đổi lịch khám", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor))),
            const SizedBox(height: 20),

            // 1. LỊCH CALENDAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Chọn ngày mới", style: TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: kPrimaryColor),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1)),
                    ),
                    Text("Th. ${_focusedMonth.month}, ${_focusedMonth.year}", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: kPrimaryColor),
                      onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1)),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"].map((e) => Text(e, style: const TextStyle(color: kGreyTextColor, fontWeight: FontWeight.bold))).toList(),
                  ),
                  const SizedBox(height: 10),
                  _buildCalendarGrid(availableDateStrings),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. KHUNG GIỜ TRỐNG
            const Text("Khung giờ trống", style: TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_selectedDate == null)
              const Text("Vui lòng chọn một ngày trên lịch.", style: TextStyle(color: kGreyTextColor))
            else if (activeSlots.isEmpty)
              const Text("Không có lịch khám vào ngày này.", style: TextStyle(color: kGreyTextColor))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: activeSlots.map((slot) {
                  // 🌟 Thêm logic so sánh thời gian thực tế
                  String timeString = slot.time.split('-')[0].trim();
                  List<String> timeParts = timeString.split(':');
                  int hour = int.parse(timeParts[0]);
                  int minute = int.parse(timeParts[1]);

                  DateTime slotDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    hour,
                    minute,
                  );

                  DateTime now = DateTime.now();
                  bool isPast = slotDateTime.isBefore(now); // Đã qua giờ hiện tại
                  bool isBooked = slot.status == 'booked';
                  
                  // Chỉ cho phép bấm khi trạng thái available VÀ chưa qua giờ
                  bool isAvailable = slot.status == 'available' && !isPast;
                  bool isSelected = _selectedSlotId == slot.id;

                  Color bgColor; 
                  Color borderColor = Colors.transparent; 
                  Color textColor; 

                  if (isPast || isBooked) {
                    // Bôi xám, vô hiệu hóa, không gạch ngang chữ
                    bgColor = Colors.grey.shade300; 
                    textColor = Colors.grey.shade600; 
                  } else if (isAvailable) {
                    bgColor = isSelected ? kPrimaryColor : kPrimaryColor.withOpacity(0.1);
                    borderColor = isAvailable ? kPrimaryColor.withOpacity(0.4) : Colors.transparent;
                    textColor = isSelected ? Colors.white : kPrimaryColor;
                  } else { 
                    bgColor = Colors.white; 
                    borderColor = Colors.grey.shade300; 
                    textColor = Colors.grey.shade400;
                  }

                  return GestureDetector(
                    onTap: isAvailable ? () => setState(() => _selectedSlotId = slot.id) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: bgColor, 
                        borderRadius: BorderRadius.circular(15), 
                        border: Border.all(color: borderColor)
                      ),
                      // 🌟 Xóa bỏ TextDecoration.lineThrough
                      child: Text(slot.time, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              
            const SizedBox(height: 30),

            // 3. NÚT XÁC NHẬN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSlotId == null ? null : () => _executeReschedule(context),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("Xác nhận đổi lịch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<String> availableDateStrings) {
    DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int firstWeekday = firstDayOfMonth.weekday;
    int totalSlots = (firstWeekday - 1) + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) return const SizedBox(); 
        int day = index - (firstWeekday - 1) + 1;
        DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        String currentGridDate = _formatDate(cellDate);
        bool isSelected = _selectedDate != null && _selectedDate!.year == cellDate.year && _selectedDate!.month == cellDate.month && _selectedDate!.day == cellDate.day;
        bool isPast = cellDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
        bool isDisabled = isPast || !availableDateStrings.contains(currentGridDate);

        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() { _selectedDate = cellDate; _selectedSlotId = null; }),
          child: Container(
            decoration: BoxDecoration(color: isSelected ? kPrimaryColor : Colors.transparent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              day.toString(), 
              style: TextStyle(
                color: isDisabled ? Colors.grey.shade300 : (isSelected ? Colors.white : kTextColor), 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )
            ),
          ),
        );
      },
    );
  }

  // Thực thi đổi lịch
  Future<void> _executeReschedule(BuildContext context) async {
    final appVM = context.read<AppointmentViewModel>();
    final result = await appVM.rescheduleAppointment(widget.appointmentId, _selectedSlotId!);

    if (context.mounted) {
      Navigator.pop(context); // Đóng BottomSheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['succeeded'] ? Colors.green : Colors.red,
        ),
      );
      if (result['succeeded'] == true) {
        appVM.fetchDetail(widget.appointmentId); // Tải lại chi tiết để hiển thị giờ mới
      }
    }
  }
}