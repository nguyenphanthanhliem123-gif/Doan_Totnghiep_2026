import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart'; // Import để lấy ID bệnh nhân
import '../models/doctor_detail_model.dart'; // Import Model bác sĩ

class BookingScreen extends StatefulWidget {
  final DoctorDetailModel doctor; // Nhận dữ liệu thật từ trang trước

  const BookingScreen({super.key, required this.doctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Biến quản lý Lịch (Calendar)
  DateTime _focusedMonth = DateTime.now(); // Tháng đang hiển thị
  DateTime? _selectedDate; // Ngày được bệnh nhân chấm vào

  int? _selectedSlotId; 
  bool _isForSelf = true; 
  bool _isOffline = true; 
  
  DoctorServiceModel? _selectedService; // Dịch vụ được chọn
  final TextEditingController _symptomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mặc định chọn dịch vụ đầu tiên trong danh sách của bác sĩ
    if (widget.doctor.services.isNotEmpty) {
      _selectedService = widget.doctor.services.first;
    }
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  // Hàm hỗ trợ format DateTime thành chuỗi "YYYY-MM-DD" để so sánh với DB
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy danh sách những ngày bác sĩ có lịch trống từ mảng schedules đã tải
    List<String> availableDateStrings = widget.doctor.schedules.map((s) => s.date).toList();

    // 2. Lấy danh sách khung giờ của cái ngày đang được chọn trên lịch
    List<DoctorTimeSlotModel> activeSlots = [];
    if (_selectedDate != null) {
      String selectedDateStr = _formatDate(_selectedDate!);
      // Tìm trong lịch của bác sĩ xem ngày này có khung giờ nào không
      final scheduleForDay = widget.doctor.schedules.firstWhere(
        (s) => s.date == selectedDateStr,
        orElse: () => DoctorScheduleModel(date: '', slots: []),
      );
      activeSlots = scheduleForDay.slots;
    }

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
                  // ==========================================
                  // 1. LỊCH CALENDAR (THUẦN DATETIME FLUTTER)
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Chọn ngày khám"),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: kPrimaryColor),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                              });
                            },
                          ),
                          Text(
                            "Tháng ${_focusedMonth.month}, ${_focusedMonth.year}", 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: kPrimaryColor),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                              .map((e) => Text(e, style: const TextStyle(color: kGreyTextColor, fontWeight: FontWeight.bold)))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        // Gọi hàm vẽ lưới ngày
                        _buildCalendarGrid(availableDateStrings),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ==========================================
                  // 2. KHUNG GIỜ TRỐNG
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Khung giờ trống"),
                      Row(
                        children: [
                          _buildLegendIndicator(kPrimaryColor.withOpacity(0.2), "Còn trống"),
                          const SizedBox(width: 10),
                          _buildLegendIndicator(Colors.grey.shade200, "Đầy chỗ"),
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
                        bool isSelected = _selectedSlotId == slot.id;

                        return GestureDetector(
                          onTap: isAvailable ? () {
                            setState(() { _selectedSlotId = slot.id; });
                          } : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? (isSelected ? kPrimaryColor : kPrimaryColor.withOpacity(0.1))
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isAvailable ? kPrimaryColor.withOpacity(0.4) : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              slot.time,
                              style: TextStyle(
                                color: isAvailable
                                    ? (isSelected ? Colors.white : kPrimaryColor)
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 25),

                  // ==========================================
                  // 3. TÙY CHỌN ĐẶT CHO AI & HÌNH THỨC
                  // ==========================================
                  _buildSectionTitle("Khám cho"),
                  Row(
                    children: [
                      _buildToggleButton("Bản thân", _isForSelf, () => setState(() => _isForSelf = true)),
                      const SizedBox(width: 15),
                      _buildToggleButton("Người thân", !_isForSelf, () => setState(() => _isForSelf = false)),
                    ],
                  ),
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

                  // ==========================================
                  // 4. DỊCH VỤ KHÁM (LẤY TỪ DB THẬT)
                  // ==========================================
                  _buildSectionTitle("Dịch vụ khám"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: kInputBackgroundColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DoctorServiceModel>(
                        value: _selectedService,
                        isExpanded: true,
                        hint: const Text("Chọn dịch vụ"),
                        items: widget.doctor.services.map((service) {
                          return DropdownMenuItem<DoctorServiceModel>(
                            value: service,
                            child: Text(service.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() { _selectedService = val; });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ==========================================
                  // 5. TRIỆU CHỨNG
                  // ==========================================
                  _buildSectionTitle("Mô tả triệu chứng"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: kInputBackgroundColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
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

          // ==========================================
          // 6. THANH XÁC NHẬN VÀ GỌI API
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng cộng:", style: TextStyle(color: kGreyTextColor, fontSize: 13)),
                    Text(
                      // Tự động lấy giá tiền thật của Dịch vụ đang chọn
                      _selectedService != null 
                        ? "${_selectedService!.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ" 
                        : "0 VNĐ",
                      style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: (_selectedSlotId == null || _selectedService == null) ? null : () async {
                    
                    // 1. MÓC ID BỆNH NHÂN TỪ AuthViewModel RA
                    final authVM = context.read<AuthViewModel>();
                    final patientIdStr = await authVM.getSavedUserId();
                    
                    if (patientIdStr == null || patientIdStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch!')));
                      return;
                    }

                    int patientId = int.parse(patientIdStr);

                    // 2. GỌI API POST ĐỂ TẠO LỊCH
                    if (mounted) {
                      final result = await context.read<BookingViewModel>().submitBooking(
                        doctorId: widget.doctor.id, 
                        patientId: patientId, 
                        relativeId: _isForSelf ? null : 1, // Tạm fix 1, sau này làm quản lý người thân ráp vào
                        serviceId: _selectedService!.id,
                        slotId: _selectedSlotId!,
                        type: _isOffline ? "offline" : "online",
                        symptoms: _symptomController.text,
                      );

                      if (mounted) {
                        if (result['succeeded'] == true) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Thành công", style: TextStyle(color: Colors.green)),
                              content: Text("${result['message']}\nMã vé: ${result['data']['Ma_booking']}"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context, true); // Lùi về trang bác sĩ và báo hiệu có thay đổi để reload lại lịch
                                  },
                                  child: const Text("OK", style: TextStyle(color: kPrimaryColor)),
                                )
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Đặt lịch thất bại")));
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: context.watch<BookingViewModel>().isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Xác nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC VẼ LỊCH (CALENDAR) BẰNG DATETIME ---
  Widget _buildCalendarGrid(List<String> availableDateStrings) {
    // Tìm ngày đầu tiên của tháng
    DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Tìm tổng số ngày trong tháng đó
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    // Ngày đầu tiên rơi vào thứ mấy (1: Thứ 2, 7: Chủ Nhật)
    int firstWeekday = firstDayOfMonth.weekday;

    // Tổng số ô cần vẽ trên Grid = Khoảng trống đầu tháng + Số ngày trong tháng
    int totalSlots = (firstWeekday - 1) + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        // Những ô trống ở đầu tuần
        if (index < firstWeekday - 1) {
          return const SizedBox(); 
        }

        // Tính ra ngày hiện tại
        int day = index - (firstWeekday - 1) + 1;
        DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        String currentGridDate = _formatDate(cellDate);

        // Kiểm tra logic chọn ngày
        bool isSelected = _selectedDate != null && _selectedDate!.year == cellDate.year && _selectedDate!.month == cellDate.month && _selectedDate!.day == cellDate.day;
        
        // Disable ngày nếu nằm trong quá khứ HOẶC bác sĩ không có lịch trống
        bool isPast = cellDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
        bool isDisabled = isPast || !availableDateStrings.contains(currentGridDate);

        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() { 
              _selectedDate = cellDate; 
              _selectedSlotId = null; // Reset slot khi đổi ngày
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? kPrimaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isDisabled ? Colors.grey.shade300 : (isSelected ? Colors.white : kTextColor),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: isDisabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CÁC WIDGET HỖ TRỢ (GIỮ NGUYÊN) ---
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.white,
            border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : kTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}