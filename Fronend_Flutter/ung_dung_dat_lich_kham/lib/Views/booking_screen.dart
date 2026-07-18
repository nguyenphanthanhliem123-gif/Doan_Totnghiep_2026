import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/models/health_record_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/add_health_record.dart';
import '../Constants/ui_constants.dart'; 
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/doctor_detail_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/appointment_viewmodel.dart';
import 'dart:async'; 

class BookingScreen extends StatefulWidget {
  final DoctorDetailModel doctor; 

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedMonth = DateTime.now(); 
  DateTime? _selectedDate; 

  List<int> _selectedSlotIds = [];
  bool _isForSelf = true; 
  bool _isOffline = true; 
  String _paymentMethod = 'cash'; 
  
  List<DoctorServiceModel> _selectedServices = []; 
  HealthRecordModel? _selectedRelative; 

  final TextEditingController _symptomController = TextEditingController();
  Timer? _pollingTimer;

  List<DoctorScheduleModel> _activeSchedules = [];
  List<DoctorTimeSlotModel> _currentDaySlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    if (widget.doctor.services.isNotEmpty) {
      _selectedServices.add(widget.doctor.services.first);
    }

    _activeSchedules = List.from(widget.doctor.schedules);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordViewModel>().loadHealthRecord();
      context.read<BookingViewModel>().fetchTodayBookingCount();
    });
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  double _calculateTotalPrice() {
    // 1. Tính tổng tiền các dịch vụ đã chọn
    double serviceSum = _selectedServices.fold(0, (sum, item) => sum + item.price);
    
    // 2. Lấy số lượng khung giờ (Nếu chưa chọn khung giờ nào thì mặc định tính là 1 để hiển thị giá gốc)
    int slotCount = _selectedSlotIds.isEmpty ? 1 : _selectedSlotIds.length;
    
    // 3. Nhân tổng tiền dịch vụ với số lượng khung giờ
    return serviceSum * slotCount;
  }

  Future<void> _reloadSlots() async {
    if (_selectedDate == null) return;
    String formattedDate = _formatDate(_selectedDate!);
    setState(() => _isLoadingSlots = true);
    
    await context.read<BookingViewModel>().fetchDoctorSchedule(formattedDate, widget.doctor.id);
    await context.read<BookingViewModel>().fetchTodayBookingCount();

    List<DoctorTimeSlotModel> fetchedSlots = [];
    final rawList = context.read<BookingViewModel>().schedule;

    for (var s in rawList) {
      String displayTime = s['Gio_Kham']?.toString() ?? "Lỗi"; 
      fetchedSlots.add(DoctorTimeSlotModel(
        id: s['Ma_khung_gio'], 
        time: displayTime,
        status: s['Trang_thai'] ?? 'available'
      ));
    }

    setState(() {
      _currentDaySlots = fetchedSlots;
      _selectedSlotIds.removeWhere((id) => !_currentDaySlots.any((slot) => slot.id == id && slot.status == 'available'));
      _isLoadingSlots = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableDateStrings = widget.doctor.schedules.map((s) => s.date).toList();

    double totalPrice = _calculateTotalPrice();
    String formattedTotalPrice = "${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "BS. ${widget.doctor.fullName}",
          style: kHeaderTextStyle.copyWith(fontSize: 16), 
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kDefaultPadding), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Chọn ngày khám"),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: kPrimaryColor),
                            onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1)),
                          ),
                          Text("Tháng ${_focusedMonth.month}, ${_focusedMonth.year}", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
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
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(kBorderRadiusLarge), border: Border.all(color: kBorderCyan)), 
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
                  const SizedBox(height: kSpacingLarge),

                  // 💡 ĐÃ SỬA: Đưa khối Hạn Mức Đặt Lịch độc lập ra ngoài
                  Consumer<BookingViewModel>(
                    builder: (context, bookingVM, child) => _buildTodayBookingLimitCard(bookingVM.todayBookingCount),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Khung giờ trống"),
                      Row(
                        children: [
                          _buildLegendIndicator(kPrimaryColor.withOpacity(0.2), "Trống"),
                          const SizedBox(width: 8),
                          _buildLegendIndicator(Colors.grey.shade300, "Đầy"),
                          const SizedBox(width: 8),
                          _buildLegendIndicator(Colors.white, "Nghỉ", borderColor: Colors.grey.shade400),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  if (_isLoadingSlots)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    ))
                  else if (_selectedDate == null)
                    const Text("Vui lòng chọn một ngày trên lịch.", style: TextStyle(color: kGreyTextColor))
                  else if (_currentDaySlots.isEmpty)
                    const Text("Không có lịch khám vào ngày này hoặc các ca đã qua giờ đăng ký.", style: TextStyle(color: kGreyTextColor))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _currentDaySlots.map((slot) {
                        String timeString = slot.time.split('-')[0].trim();
                        List<String> timeParts = timeString.split(':');
                        int hour = int.parse(timeParts[0]);
                        int minute = int.parse(timeParts[1]);

                        DateTime slotDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour, minute);
                        bool isPast = slotDateTime.isBefore(DateTime.now());
                        bool isBooked = slot.status == 'booked';
                        bool isAvailable = slot.status == 'available' && !isPast; 
                        
                        bool isSelected = _selectedSlotIds.contains(slot.id);

                        Color bgColor; 
                        Color borderColor = Colors.transparent; 
                        Color textColor; 

                        if (isPast || isBooked) {
                          bgColor = Colors.grey.shade300; 
                          textColor = Colors.grey.shade600; 
                        } else if (isAvailable) {
                          bgColor = isSelected ? kPrimaryColor : kLightCyanBg1; 
                          borderColor = kPrimaryColor.withOpacity(0.4);
                          textColor = isSelected ? Colors.white : kPrimaryColor;
                        } else { 
                          bgColor = Colors.white; 
                          borderColor = Colors.grey.shade300; 
                          textColor = Colors.grey.shade400;
                        }

                        return GestureDetector(
                          onTap: isAvailable ? () {
                            final bookingVM = context.read<BookingViewModel>();
                            setState(() {
                              if (isSelected) {
                                _selectedSlotIds.remove(slot.id);
                              } else {
                                if (bookingVM.todayBookingCount + _selectedSlotIds.length >= 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Bạn không được chọn vượt quá số lượng 5 lịch hẹn đặt trong ngày!'),
                                    backgroundColor: Colors.redAccent,
                                  ));
                                  return;
                                }
                                _selectedSlotIds.add(slot.id);
                              }
                            });
                          } : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(kBorderRadiusSmall), border: Border.all(color: borderColor)), 
                            child: Text(slot.time, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: kSpacingLarge),
                  _buildSectionTitle("Khám cho"),
                  Row(
                    children: [
                      _buildToggleButton("Bản thân", _isForSelf, () => setState(() => _isForSelf = true)),
                      const SizedBox(width: 15),
                      _buildToggleButton("Người thân", !_isForSelf, () {
                        setState(() {
                          _isForSelf = false;
                          final hrVM = context.read<HealthRecordViewModel>();
                          final relatives = hrVM.listRecord?.where((r) => r.relativeId != null).toList() ?? [];
                          if (relatives.isNotEmpty && _selectedRelative == null) {
                            _selectedRelative = relatives.first;
                          }
                        });
                      }),
                    ],
                  ),
                  
                  if (!_isForSelf) ...[
                    const SizedBox(height: 15),
                    Consumer<HealthRecordViewModel>(
                      builder: (context, hrVM, child) {
                        if (hrVM.isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                        
                        final relatives = hrVM.listRecord?.where((r) => r.relativeId != null).toList() ?? [];
                        
                        if (relatives.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(kBorderRadiusSmall), border: Border.all(color: Colors.orange.shade200)),
                            child: Column(
                              children: [
                                const Text("Bạn chưa có hồ sơ người thân nào.", style: TextStyle(color: Colors.orange)),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHealthRecordScreen()));
                                  },
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                                  label: const Text("Thêm người thân", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                )
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<HealthRecordModel>(
                              value: _selectedRelative,
                              isExpanded: true,
                              hint: const Text("Chọn hồ sơ người thân", style: TextStyle(color: kGreyTextColor)),
                              items: relatives.map((relative) {
                                return DropdownMenuItem<HealthRecordModel>(
                                  value: relative,
                                  child: Text("${relative.recordName} - Mã BN: ${relative.id} (${relative.roll})", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedRelative = val),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: kSpacingLarge),

                  _buildSectionTitle("Hình thức khám"),
                  Row(
                    children: [
                      _buildToggleButton("Tại phòng khám", _isOffline, () => setState(() => _isOffline = true)),
                      const SizedBox(width: 15),
                      _buildToggleButton("Khám Online", !_isOffline, () => setState(() => _isOffline = false)),
                    ],
                  ),
                  const SizedBox(height: kSpacingLarge),

                  _buildSectionTitle("Dịch vụ khám (Có thể chọn nhiều)"),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: widget.doctor.services.map((service) {
                      bool isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service.name),
                        selected: isSelected,
                        selectedColor: kLightCyanBg1, 
                        checkmarkColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? kPrimaryColor : kTextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? kPrimaryColor : kBorderCyan)),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              if (_selectedServices.length > 1) {
                                _selectedServices.remove(service);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phải chọn ít nhất 1 dịch vụ!')));
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: kSpacingLarge),

                  _buildSectionTitle("Mô tả triệu chứng"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
                    child: TextField(
                      controller: _symptomController,
                      maxLines: 4,
                      style: const TextStyle(color: kTextColor),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Mô tả ngắn triệu chứng tại đây để bác sĩ chuẩn bị trước...",
                        hintStyle: TextStyle(color: kGreyTextColor, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 15), 
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tổng cộng:", style: TextStyle(color: kGreyTextColor, fontSize: 13)),
                      Text(
                        formattedTotalPrice,
                        style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: (_selectedSlotIds.isEmpty || _selectedServices.isEmpty) ? null : () => _showSummaryBottomSheet(context, _currentDaySlots),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall))),
                    child: const Text("Xác nhận", style: kButtonTextStyle), 
                  )
                ],
              ),
            ),
          ),
        ],
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
          onTap: isDisabled ? null : () async {
            setState(() { 
              _selectedDate = cellDate; 
              _selectedSlotIds.clear();
              _isLoadingSlots = true; 
            });

            String formattedDate = _formatDate(cellDate);
            await context.read<BookingViewModel>().fetchDoctorSchedule(formattedDate, widget.doctor.id);
            
            List<DoctorTimeSlotModel> fetchedSlots = [];
            final rawList = context.read<BookingViewModel>().schedule;

            for (var s in rawList) {
                String displayTime = s['Gio_Kham']?.toString() ?? "Lỗi"; 
                fetchedSlots.add(DoctorTimeSlotModel(
                    id: s['Ma_khung_gio'], 
                    time: displayTime,
                    status: s['Trang_thai'] ?? 'available'
                ));
            }

            setState(() {
              _currentDaySlots = fetchedSlots;
              _isLoadingSlots = false; 
            });
          },
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

  // 💡 ĐÃ SỬA: Loại bỏ widget Expanded khỏi LinearProgressIndicator và thêm MainAxisSize.min
  Widget _buildTodayBookingLimitCard(int currentCount) {
    double progress = (currentCount / 5).clamp(0.0, 1.0);
    bool isFull = currentCount >= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingLarge),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFull 
              ? [Colors.red.shade400, Colors.red.shade700] 
              : [kPrimaryColor.withOpacity(0.85), kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        boxShadow: [
          BoxShadow(color: (isFull ? Colors.red : kPrimaryColor).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Hạn mức đặt lịch trong ngày",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "$currentCount / 5 Lịch hẹn",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.amber : Colors.white),
              minHeight: 8,
            ),
          ),
          if (isFull) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Bạn đã đạt giới hạn tối đa 5 lịch trong ngày. Vui lòng quay lại vào ngày mai!",
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold));
  
  Widget _buildLegendIndicator(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: borderColor != null ? Border.all(color: borderColor) : null)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: kGreyTextColor)),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? kPrimaryColor : Colors.white, border: Border.all(color: isSelected ? kPrimaryColor : kBorderCyan), borderRadius: BorderRadius.circular(kBorderRadiusLarge)), 
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : kTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  void _showSummaryBottomSheet(BuildContext context, List<DoctorTimeSlotModel> activeSlots) {
    final hrVM = context.read<HealthRecordViewModel>();
    
    HealthRecordModel? targetRecord;
    String forWhom = "";

    if (_isForSelf) {
      targetRecord = hrVM.listRecord?.firstWhere(
        (r) => r.relativeId == null || r.relationship == 'Bản thân',
        orElse: () => null as dynamic,
      );
      if (targetRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy dữ liệu hồ sơ Bản thân! Vui lòng tạo hồ sơ trước.')),
        );
        return;
      }
      forWhom = "Bản thân (${targetRecord.recordName})";
    } else {
      if (_selectedRelative == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn hồ sơ người thân!')));
        return;
      }
      targetRecord = _selectedRelative;
      forWhom = "Người thân (${targetRecord!.recordName})";
    }

    final selectedSlots = activeSlots.where((slot) => _selectedSlotIds.contains(slot.id)).toList();
    String timeDisplay = selectedSlots.map((s) => s.time).join(", ");
    String serviceNames = _selectedServices.map((s) => s.name).join(", ");
    double totalPrice = _calculateTotalPrice();
    final String formattedPrice = "${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} Đ";
    
    if (_isOffline) {
      _paymentMethod = 'cash'; 
    } else {
      _paymentMethod = 'vnpay'; 
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              padding: EdgeInsets.only(top: 20, left: kDefaultPadding, right: kDefaultPadding, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Center(child: Text("Xác Nhận Đặt Lịch", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor))),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
                    child: Row(
                      children: [
                        CircleAvatar(radius: 30, backgroundImage: widget.doctor.avatar != null ? NetworkImage(widget.doctor.avatar!) : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("BS. ${widget.doctor.fullName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor)),
                              const SizedBox(height: 5),
                              Text("${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • $timeDisplay", style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow("Đặt cho", forWhom), 
                  _buildSummaryRow("Hình thức", _isOffline ? "Tại phòng khám" : "Khám Online"),
                  _buildSummaryRow("Dịch vụ", serviceNames), 
                  const Divider(height: 30, color: kBorderCyan),
                  _buildSummaryRow("Phí khám", formattedPrice, isTotal: true),
                  const SizedBox(height: 15),

                  const Text("Phương thức thanh toán:", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_isOffline) 
                        _buildPaymentButton("Thanh toán tại quầy", "cash", Icons.money, setModalState),
                      if (!_isOffline) 
                        _buildPaymentButton("VNPay", "vnpay", Icons.payment_rounded, setModalState),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: kPrimaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge))), 
                          child: const Text("Hủy bỏ", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _executeBooking(ctx), 
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)), elevation: 0), 
                          child: context.watch<BookingViewModel>().isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_paymentMethod == 'cash' ? "Xác nhận" : "Thanh toán", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildPaymentButton(String label, String value, IconData icon, StateSetter setModalState) {
    bool isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() { _paymentMethod = value; }); 
          setState(() { _paymentMethod = value; }); 
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? kLightCyanBg1 : Colors.white, border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey, size: 20),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 12, color: isSelected ? kPrimaryColor : kTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kGreyTextColor)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(color: isTotal ? kPrimaryColor : kTextColor, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, fontSize: isTotal ? 16 : 14)
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBooking(BuildContext bottomSheetContext) async {
    final authVM = context.read<AuthViewModel>();
    final bookingVM = context.read<BookingViewModel>();
    final hrVM = context.read<HealthRecordViewModel>();
    
    final patientIdStr = await authVM.getSavedUserId();
    if (patientIdStr == null || patientIdStr.isEmpty){ 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch!')));
      }
      return; 
    }

    int? finalPatientId;
    int? finalRelativeId;

    if (_isForSelf) {
      final selfRecord = hrVM.listRecord?.firstWhere((r) => r.relativeId == null || r.relationship == 'Bản thân', orElse: () => null as dynamic);
      if (selfRecord != null) { finalPatientId = selfRecord.id; finalRelativeId = null; }
    } else {
      if (_selectedRelative != null) { finalPatientId = _selectedRelative!.id; finalRelativeId = _selectedRelative!.relativeId; }
    }

    if (finalPatientId == null || finalPatientId == 0) return;

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    List<int> serviceIds = _selectedServices.map((e) => e.id).toList();

    // 🔴 DEBUG 1: Kiểm tra phương thức thanh toán Flutter đang giữ trước khi gửi đi
    print("=== DEBUG: Hình thức khám: ${_isOffline ? 'Offline' : 'Online'} | Phương thức thanh toán: $_paymentMethod ===");

    final result = await bookingVM.submitBooking(
      doctorId: widget.doctor.id, 
      patientId: finalPatientId, 
      relativeId: finalRelativeId, 
      serviceIds: serviceIds, 
      slotIds: _selectedSlotIds, 
      type: _isOffline ? "offline" : "online",
      symptoms: _symptomController.text,
      paymentMethod: _paymentMethod, 
    );

    if (mounted) Navigator.pop(context); // Tắt vòng xoay Loading chính

    if (mounted) {
      if (result['succeeded'] == true) {
        Navigator.pop(bottomSheetContext); // Đóng BottomSheet tổng quan
        
        // Lấy mã chuỗi gộp do Backend trả về
        String bookingCode = result['combinedBookingCode']?.toString() ?? 
                            result['data']?['combinedBookingCode']?.toString() ?? '';
        
        if (bookingCode.isEmpty) {
          List<dynamic> bookingList = result['data'] is List ? result['data'] : [result['data']];
          bookingCode = bookingList.map((b) => b['Ma_booking'].toString()).join('-');
        }
        
        String amount = result['totalPrice'].toString();

        // 🔴 DEBUG 2: Xem mã đặt lịch và số tiền hệ thống nhận được
        print("=== DEBUG: Đặt chuỗi lịch thành công! Mã hóa đơn: $bookingCode | Tổng tiền: $amount ===");

        context.read<AppointmentViewModel>().loadMyAppointments();
        await _reloadSlots(); 

        // XỬ LÝ THANH TOÁN ONLINE VNPAY
        if (_paymentMethod == 'vnpay') {
          print("=== DEBUG: Đang tiến hành gọi API khởi tạo liên kết VNPay... ===");
          final vnpayResult = await bookingVM.createVnpayPayment(bookingCode: bookingCode);
          
          // 🔴 DEBUG 3: In toàn bộ cấu trúc phản hồi từ API VNPay ra Console
          print("=== DEBUG: Phản hồi từ API VNPay: $vnpayResult ===");

          if (mounted) {
            if (vnpayResult['succeeded'] == true && vnpayResult['paymentUrl'] != null) {
              final String cleanUrl = vnpayResult['paymentUrl'].toString().trim();
              
              print("=== DEBUG: [THÀNH CÔNG] Kích hoạt hiển thị Dialog VNPay trung gian ===");
              
              // Gọi hàm mở Dialog hiển thị thông tin thay vì chuyển hướng ngay lập tức
              _showVNPayDialog(bookingCode, amount, cleanUrl);
              
            } else {
              // Trường hợp API VNPay trả về thất bại (Sai cấu hình file .env backend, vnp_TmnCode...)
              String vnpayError = vnpayResult['message'] ?? "Không thể khởi tạo cổng thanh toán VNPay từ máy chủ.";
              print("=== DEBUG: [THẤT BẠI] API VNPay báo lỗi: $vnpayError ===");
              _showErrorDialog(vnpayError);

              if (!_isOffline) {
                print("=== DEBUG: Đang tự động giải phóng chuỗi khung giờ do VNPay lỗi... ===");
                await bookingVM.cancelCombinedUnpaidBooking(bookingCode);
                await _reloadSlots(); 
                context.read<AppointmentViewModel>().loadMyAppointments();
              }
            }
          }
        } else {
          // Nếu lọt vào nhánh Tiền mặt (offline)
          print("=== DEBUG: Luồng chạy rẽ vào nhánh thanh toán tại quầy (Cash) ===");
          _showSuccessDialog(result['message'] ?? "Đặt lịch thành công!", bookingCode);
        }
      } else {
        Navigator.pop(bottomSheetContext);
        String errorMsg = result['message'] ?? "Có lỗi xảy ra trong quá trình đặt lịch.";
        print("=== DEBUG: Gọi API đặt lịch thất bại hoàn toàn: $errorMsg ===");

        if (result['requiresReload'] == true) {
          await _reloadSlots(); 
        }
        _showErrorDialog(errorMsg);
      }
    }
  }

  void _showVNPayDialog(String bookingCode, String amount, String paymentUrl) {
    final String formattedAmount = "${amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ";
    String displayCodes = bookingCode.replaceAll('-', ', ');

    showDialog(
      context: context, barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_rounded, color: kPrimaryColor, size: 24),
              const SizedBox(width: 8),
              Text("Thanh toán VNPay", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhấn nút dưới đây để mở website cổng thanh toán VNPay để tiến hành thanh toán.", textAlign: TextAlign.center, style: TextStyle(color: kGreyTextColor, fontSize: 13)),
            const SizedBox(height: 20),
            Text("Số tiền: $formattedAmount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 10),
            const Text("Mã lịch hẹn cần thanh toán:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kGreyTextColor)),
            const SizedBox(height: 4),
            Text(displayCodes, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor, fontSize: 14)),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                  label: const Text("Mở Cổng VNPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final String cleanUrl = paymentUrl.trim();
                    final Uri url = Uri.parse(cleanUrl);
                    try {
                      // 🛠️ TỐI ƯU UX: Đóng Dialog trung gian này trước khi chuyển hướng ứng dụng
                      Navigator.pop(ctx); 
                      
                      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                      if (!launched) await launchUrl(url, mode: LaunchMode.inAppWebView);
                      
                      if (!mounted) return;
                      // Kích hoạt ngay cổng tự động check trạng thái hóa đơn
                      _showAutoCheckPaymentDialog(bookingCode);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể mở cổng thanh toán. Lỗi: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx); 
                    
                    showDialog(
                      context: context, 
                      barrierDismissible: false, 
                      builder: (context) => const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    );
                    
                    await context.read<BookingViewModel>().cancelCombinedUnpaidBooking(bookingCode);
                    await _reloadSlots();
                    if (mounted) Navigator.pop(context); 

                    if (mounted) {
                      context.read<AppointmentViewModel>().loadMyAppointments(); 
                      _showErrorDialog("Giao dịch VNPay đã bị hủy. Lịch hẹn tạm thời của bạn đã được giải phóng.");
                    }
                  },
                  child: const Text("Hủy bỏ giao dịch", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, String bookingCode) {
    // 🛠️ ĐÃ SỬA: Chuyển dấu '-' thành dấu ', ' để hiển thị đẹp mắt cho người dùng
    String displayCodes = bookingCode.replaceAll('-', ', ');

    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusLarge)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text("Tuyệt vời!", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("$message\n\nMã lịch hẹn của bạn:\n$displayCodes", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () { 
                Navigator.pop(ctx); 
                Navigator.pop(ctx); 
                Navigator.pop(context, true); 
              },
              child: const Text("Quay về", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showAutoCheckPaymentDialog(String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Đang chờ thanh toán...", textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 20),
            Text(
              "Vui lòng hoàn tất thanh toán trên trình duyệt web.\nHệ thống đang tự động kiểm tra kết quả...",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () async {
                _pollingTimer?.cancel(); 
                Navigator.pop(ctx); 
                
                showDialog(
                  context: context, 
                  barrierDismissible: false, 
                  builder: (context) => const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                );
                
                await context.read<BookingViewModel>().cancelCombinedUnpaidBooking(bookingCode);
                await _reloadSlots();
                if (mounted) Navigator.pop(context); 
                
                context.read<AppointmentViewModel>().loadMyAppointments();
                _showErrorDialog("Bạn đã hủy quá trình đợi phản hồi thanh toán. Khung giờ khám hiện tại đã được giải phóng thành công.");
              },
              child: const Text("Hủy bỏ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    final bookingVM = context.read<BookingViewModel>();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final status = await bookingVM.checkCombinedPaymentStatus(bookingCode);

      if (status == 'paid') {
        timer.cancel(); 
        if (mounted) {
          Navigator.pop(context); // Tắt loading dialog tự động check
          _showSuccessDialog("Thanh toán điện tử thành công!", bookingCode); 
        }
      } else if (status == 'failed' || status == 'cancelled') {
        timer.cancel();
        if (mounted) {
          Navigator.pop(context); 
          _showErrorDialog("Giao dịch thanh toán thất bại hoặc phía ngân hàng đã từ chối cấp quyền.");
        }
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)), 
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Xác nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}