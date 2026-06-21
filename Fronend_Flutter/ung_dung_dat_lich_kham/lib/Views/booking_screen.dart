import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/models/health_record_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/health_record_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/views/add_health_record.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/doctor_detail_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingScreen extends StatefulWidget {
  final DoctorDetailModel doctor; 

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedMonth = DateTime.now(); 
  DateTime? _selectedDate; 

  int? _selectedSlotId; 
  bool _isForSelf = true; 
  bool _isOffline = true; 
  String _paymentMethod = 'cash'; 
  
  // 🌟 THAY ĐỔI: Chuyển từ biến đơn sang List để lưu nhiều dịch vụ
  List<DoctorServiceModel> _selectedServices = []; 
  HealthRecordModel? _selectedRelative; 

  final TextEditingController _symptomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mặc định chọn dịch vụ đầu tiên
    if (widget.doctor.services.isNotEmpty) {
      _selectedServices.add(widget.doctor.services.first);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordViewModel>().loadHealthRecord();
    });
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 🌟 HÀM TÍNH TỔNG TIỀN CHO NHIỀU DỊCH VỤ
  double _calculateTotalPrice() {
    return _selectedServices.fold(0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableDateStrings = widget.doctor.schedules.map((s) => s.date).toList();

    List<DoctorTimeSlotModel> activeSlots = [];
    if (_selectedDate != null) {
      String selectedDateStr = _formatDate(_selectedDate!);
      final scheduleForDay = widget.doctor.schedules.firstWhere(
        (s) => s.date == selectedDateStr,
        orElse: () => DoctorScheduleModel(date: '', slots: []),
      );
      activeSlots = scheduleForDay.slots;
    }

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LỊCH CALENDAR
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
                  const SizedBox(height: 25),

                  // 2. KHUNG GIỜ TRỐNG
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
                  if (_selectedDate == null)
                    const Text("Vui lòng chọn một ngày trên lịch.", style: TextStyle(color: kGreyTextColor))
                  else if (activeSlots.isEmpty)
                    const Text("Không có lịch khám vào ngày này.", style: TextStyle(color: kGreyTextColor))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: activeSlots.map((slot) {
                        bool isAvailable = slot.status == 'available';
                        bool isBooked = slot.status == 'booked';
                        bool isSelected = _selectedSlotId == slot.id;

                        Color bgColor; Color borderColor = Colors.transparent; Color textColor; TextDecoration? textDecoration;
                        if (isAvailable) {
                          bgColor = isSelected ? kPrimaryColor : kPrimaryColor.withOpacity(0.1);
                          borderColor = isAvailable ? kPrimaryColor.withOpacity(0.4) : Colors.transparent;
                          textColor = isSelected ? Colors.white : kPrimaryColor;
                        } else if (isBooked) {
                          bgColor = Colors.grey.shade300; textColor = Colors.grey.shade600; textDecoration = TextDecoration.lineThrough;
                        } else { 
                          bgColor = Colors.white; borderColor = Colors.grey.shade300; textColor = Colors.grey.shade400;
                        }

                        return GestureDetector(
                          onTap: isAvailable ? () => setState(() => _selectedSlotId = slot.id) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor)),
                            child: Text(slot.time, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, decoration: textDecoration)),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 25),

                  // 3. TÙY CHỌN KHÁM CHO AI VÀ HÌNH THỨC
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
                        if (hrVM.isLoading) return const Center(child: CircularProgressIndicator());
                        
                        final relatives = hrVM.listRecord?.where((r) => r.relativeId != null).toList() ?? [];
                        
                        if (relatives.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)),
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
                          decoration: BoxDecoration(color: kInputBackgroundColor, borderRadius: BorderRadius.circular(15)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<HealthRecordModel>(
                              value: _selectedRelative,
                              isExpanded: true,
                              hint: const Text("Chọn hồ sơ người thân"),
                              items: relatives.map((relative) {
                                return DropdownMenuItem<HealthRecordModel>(
                                  value: relative,
                                  child: Text("${relative.recordName} (${relative.roll})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedRelative = val),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 25),

                  _buildSectionTitle("Hình thức khám"),
                  Row(
                    children: [
                      _buildToggleButton("Tại phòng khám", _isOffline, () => setState(() => _isOffline = true)),
                      const SizedBox(width: 15),
                      _buildToggleButton("Khám Online", !_isOffline, () => setState(() => _isOffline = false)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 🌟 4. DỊCH VỤ KHÁM (CHỌN NHIỀU)
                  _buildSectionTitle("Dịch vụ khám (Có thể chọn nhiều)"),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: widget.doctor.services.map((service) {
                      bool isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service.name),
                        selected: isSelected,
                        selectedColor: kPrimaryColor.withOpacity(0.2),
                        checkmarkColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? kPrimaryColor : kTextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: kInputBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? kPrimaryColor : Colors.transparent)),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              // Bắt buộc phải chọn ít nhất 1 dịch vụ
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
                  const SizedBox(height: 25),

                  // 5. TRIỆU CHỨNG
                  _buildSectionTitle("Mô tả triệu chứng"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: kInputBackgroundColor, borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _symptomController,
                      maxLines: 4,
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

          // 6. THANH XÁC NHẬN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
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
                  onPressed: (_selectedSlotId == null || _selectedServices.isEmpty) ? null : () => _showSummaryBottomSheet(context, activeSlots),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Xác nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
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
          onTap: isDisabled ? null : () => setState(() { _selectedDate = cellDate; _selectedSlotId = null; }),
          child: Container(
            decoration: BoxDecoration(color: isSelected ? kPrimaryColor : Colors.transparent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(day.toString(), style: TextStyle(color: isDisabled ? Colors.grey.shade300 : (isSelected ? Colors.white : kTextColor), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, decoration: isDisabled ? TextDecoration.lineThrough : null)),
          ),
        );
      },
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
          decoration: BoxDecoration(color: isSelected ? kPrimaryColor : Colors.white, border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : kTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  void _showSummaryBottomSheet(BuildContext context, List<DoctorTimeSlotModel> activeSlots) {
    if (!_isForSelf && _selectedRelative == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn hồ sơ người thân!')));
      return;
    }

    final selectedSlot = activeSlots.firstWhere((slot) => slot.id == _selectedSlotId);
    
    // Tên các dịch vụ gộp lại bằng dấu phẩy
    String serviceNames = _selectedServices.map((s) => s.name).join(", ");
    double totalPrice = _calculateTotalPrice();
    final String formattedPrice = "${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} Đ";
    
    if (!_isOffline && _paymentMethod == 'cash') _paymentMethod = 'vnpay'; 

    String forWhom = _isForSelf ? "Bản thân" : "Người thân (${_selectedRelative!.recordName})";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                    decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
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
                              Text("${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • ${selectedSlot.time}", style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow("Đặt cho", forWhom), 
                  _buildSummaryRow("Hình thức", _isOffline ? "Tại phòng khám" : "Khám Online"),
                  _buildSummaryRow("Dịch vụ", serviceNames), // Hiển thị nhiều dịch vụ
                  const Divider(height: 30),
                  _buildSummaryRow("Phí khám", formattedPrice, isTotal: true),
                  const SizedBox(height: 15),

                  const Text("Phương thức thanh toán:", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_isOffline) _buildPaymentButton("Tiền mặt", "cash", Icons.money, setModalState),
                      if (_isOffline) const SizedBox(width: 10),
                      _buildPaymentButton("VNPay", "vnpay", Icons.payment_rounded, setModalState),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: kPrimaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: const Text("Hủy bỏ", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _executeBooking(ctx), 
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
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
          decoration: BoxDecoration(color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white, border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
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
    
    final patientIdStr = await authVM.getSavedUserId();
    if (patientIdStr == null || patientIdStr.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch!')));
      }
      return;
    }

    if (mounted) {
      // 🌟 TRUYỀN MẢNG ID DỊCH VỤ VÀO API
      List<int> serviceIds = _selectedServices.map((e) => e.id).toList();

      final result = await bookingVM.submitBooking(
        doctorId: widget.doctor.id, 
        patientId: int.parse(patientIdStr), 
        relativeId: _isForSelf ? null : _selectedRelative?.relativeId, 
        serviceIds: serviceIds, 
        slotId: _selectedSlotId!,
        type: _isOffline ? "offline" : "online",
        symptoms: _symptomController.text,
        paymentMethod: _paymentMethod, 
      );

      if (mounted) {
        if (result['succeeded'] == true) {
          Navigator.pop(bottomSheetContext);
          
          String bookingCode = result['data']['Ma_booking'];
          String amount = result['data']['Tong_tien'].toString();

          if (_paymentMethod == 'vnpay') {
            final vnpayResult = await bookingVM.createVnpayPayment(bookingCode: bookingCode);
            if (mounted) {
              if (vnpayResult['succeeded'] == true) {
                _showVNPayDialog(bookingCode, amount, vnpayResult['paymentUrl']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vnpayResult['message'] ?? "Lỗi cổng thanh toán VNPay")));
              }
            }
          } else {
            _showSuccessDialog(result['message'], bookingCode);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Đặt lịch thất bại")));
        }
      }
    }
  }

  void _showVNPayDialog(String bookingCode, String amount, String paymentUrl) {
    final String formattedAmount = "${amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ";

    showDialog(
      context: context, barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text("Thanh toán VNPay", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhấn nút dưới đây để mở website cổng thanh toán VNPay ảo để tiến hành thanh toán.", textAlign: TextAlign.center, style: TextStyle(color: kGreyTextColor, fontSize: 13)),
            const SizedBox(height: 20),
            Text("Số tiền: $formattedAmount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 4),
            Text("Nội dung: $bookingCode", style: const TextStyle(fontWeight: FontWeight.w500, color: kTextColor)),
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
                      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                      if (!launched) await launchUrl(url, mode: LaunchMode.inAppWebView);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể mở cổng thanh toán. Lỗi: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx); 
                    _showSuccessDialog("Hệ thống đang ghi nhận thanh toán của bạn!", bookingCode);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.blue.shade700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text("Tôi đã thanh toán xong", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, String bookingCode) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text("Tuyệt vời!"),
        content: Text("$message\n\nMã vé của bạn là: $bookingCode", textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context, true); },
              child: const Text("Quay về", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}