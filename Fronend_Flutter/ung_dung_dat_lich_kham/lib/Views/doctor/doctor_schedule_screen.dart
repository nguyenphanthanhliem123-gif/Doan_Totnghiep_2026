import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Models/schedule_config_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/schedule_config_viewmodel.dart';
import '../../Constants/ui_constants.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleConfigViewmodel>().loadScheduleConfig();
    });
  }

  String _getDayName(int thu) => thu == 8 ? "Chủ Nhật" : "Thứ $thu";

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScheduleConfigViewmodel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2, // 🌟 Đồng bộ màu nền
      appBar: AppBar(
        title: const Text('Cấu hình lịch làm việc', style: kHeaderTextStyle), // 🌟 Chuẩn hóa Text style
        backgroundColor: kPrimaryColor, // 🌟 Đồng bộ màu chủ đạo chuẩn hệ thống
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Tự động phát sinh lịch',
            icon: const Icon(Icons.auto_awesome_motion),
            onPressed: () => _showGenerateSlotsPicker(context, viewModel),
          ),
          /*IconButton(
            tooltip: 'Báo nghỉ / Khóa lịch ca khám',
            icon: const Icon(Icons.event_busy, color: Colors.amberAccent),
            onPressed: () => _openLeaveDialog(context, viewModel),
          ),*/
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              children: [
                _buildGlobalConfigHeader(context, viewModel),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(kDefaultPadding), // Lề 20 chuẩn
                    itemCount: 7, 
                    itemBuilder: (context, index) {
                      int thu = index + 2; 
                      return _buildDayCard(context, thu, viewModel);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGlobalConfigHeader(BuildContext context, ScheduleConfigViewmodel viewModel) {
    final config = viewModel.currentConfig;
    if (config == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorderCyan)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(Icons.timelapse, "${config.slotTime} phút", "TG Khám/Ca"),
              _buildInfoItem(Icons.coffee, "${config.breakTime} phút", "Nghỉ giữa ca"),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), // Bo 12
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Chỉnh sửa cấu hình chung", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showGlobalConfigBottomSheet(context, config, viewModel),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor)),
        Text(label, style: const TextStyle(color: kGreyTextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, int thu, ScheduleConfigViewmodel viewModel) {
    final shifts = viewModel.getShiftsForDay(thu);
    
    bool isConfigured = shifts.isNotEmpty;
    bool isDayOff = isConfigured && shifts.every((s) => s.trangThai == 'nghi');
    
    Color statusColor;
    String statusText;
    Widget subtitle;

    if (!isConfigured) {
      statusColor = kGreyTextColor;
      statusText = "Chưa cấu hình";
      subtitle = const Text("Nhấn để thiết lập ca làm việc", style: TextStyle(color: kGreyTextColor, fontSize: 13));
    } else if (isDayOff) {
      statusColor = Colors.redAccent;
      statusText = "Nghỉ";
      subtitle = const Text("Ngày nghỉ ngơi", style: TextStyle(color: Colors.redAccent, fontSize: 13));
    } else {
      statusColor = kPrimaryColor;
      statusText = "Làm việc";
      final activeShifts = shifts.where((s) => s.trangThai == 'lam').map((s) {
        String buoiStr = s.buoi == 'sang' ? "Sáng" : s.buoi == 'chieu' ? "Chiều" : "Tối";
        return "$buoiStr (${s.gioBatDau}-${s.gioKetThuc})";
      }).join(" • ");
      
      subtitle = Text(activeShifts, style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w500, fontSize: 13));
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo tròn 20 hệ thống
        side: const BorderSide(color: kBorderCyan),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
        onTap: () => _showEditBottomSheet(context, thu, shifts, viewModel),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_getDayName(thu), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    subtitle,
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_rounded, color: kPrimaryColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, int thu, List<WeeklyScheduleItem> existingShifts, ScheduleConfigViewmodel viewModel) {
    List<WeeklyScheduleItem> localShifts = [
      _getOrInitShift(existingShifts, thu, 'sang', '08:00', '12:00'),
      _getOrInitShift(existingShifts, thu, 'chieu', '13:00', '17:00'),
      _getOrInitShift(existingShifts, thu, 'toi', '18:00', '21:00'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))),
      builder: (ctx) {
        return _buildBottomSheetWithScroll(ctx, thu, localShifts, viewModel);
      },
    );
  }

  Widget _buildBottomSheetWithScroll(BuildContext ctx, int thu, List<WeeklyScheduleItem> localShifts, ScheduleConfigViewmodel viewModel) {
    return StatefulBuilder(
      builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(top: 20, left: kDefaultPadding, right: kDefaultPadding, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Text("Cấu hình ${_getDayName(thu)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
              const Divider(height: 30, color: kBorderCyan),
              
              ...List.generate(localShifts.length, (index) {
                return _buildShiftEditor(
                  localShifts[index], 
                  (updatedShift) {
                    setModalState(() {
                      localShifts[index] = updatedShift;
                    });
                  },
                );
              }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _saveConfigForDay(thu, localShifts, viewModel);
                  },
                  child: const Text("Lưu Cấu Hình Ngày Này", style: kButtonTextStyle),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showGlobalConfigBottomSheet(BuildContext context, DoctorScheduleConfigModel config, ScheduleConfigViewmodel viewModel) {
    final slotController = TextEditingController(text: config.slotTime.toString());
    final breakController = TextEditingController(text: config.breakTime.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(top: 20, left: kDefaultPadding, right: kDefaultPadding, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                const Text("Cấu hình thời gian chung", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const Divider(height: 20, color: kBorderCyan),
                
                TextFormField(
                  controller: slotController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kTextColor),
                  decoration: const InputDecoration(
                    labelText: "Thời gian khám mỗi ca (phút)",
                    prefixIcon: Icon(Icons.timelapse, color: kPrimaryColor),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || int.tryParse(val) == null) ? "Vui lòng nhập số phút hợp lệ" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: breakController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kTextColor),
                  decoration: const InputDecoration(
                    labelText: "Thời gian nghỉ giữa các ca (phút)",
                    prefixIcon: Icon(Icons.coffee, color: kPrimaryColor),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || int.tryParse(val) == null) ? "Vui lòng nhập số phút hợp lệ" : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx);
                        
                        DoctorScheduleConfigModel newConfig = DoctorScheduleConfigModel(
                          slotTime: int.parse(slotController.text),
                          breakTime: int.parse(breakController.text),
                          weeklySchedule: config.weeklySchedule, 
                        );

                        await viewModel.saveScheduleConfig(newConfig);
                        bool success = viewModel.scheduleConfigResult;
                        
                        if (context.mounted) {
                          if(success){
                            context.read<ScheduleConfigViewmodel>().loadScheduleConfig();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? 'Cập nhật cấu hình chung thành công!' : 'Cập nhật cấu hình thất bại.'),
                            backgroundColor: success ? kPrimaryColor : Colors.red,
                          ));
                        }
                      }
                    },
                    child: const Text("Lưu Cấu Hình Chung", style: kButtonTextStyle),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  WeeklyScheduleItem _getOrInitShift(List<WeeklyScheduleItem> existings, int thu, String buoi, String defaultStart, String defaultEnd) {
    final found = existings.where((s) => s.buoi == buoi).toList();
    if (found.isNotEmpty) {
      return WeeklyScheduleItem(thu: thu, buoi: buoi, gioBatDau: found.first.gioBatDau, gioKetThuc: found.first.gioKetThuc, trangThai: found.first.trangThai);
    }
    return WeeklyScheduleItem(thu: thu, buoi: buoi, gioBatDau: defaultStart, gioKetThuc: defaultEnd, trangThai: 'nghi');
  }

  Widget _buildShiftEditor(WeeklyScheduleItem shift, Function(WeeklyScheduleItem) onShiftChanged) {
    bool isWorking = shift.trangThai == 'lam';
    String buoiLabel = shift.buoi == 'sang' ? "Ca Sáng" : shift.buoi == 'chieu' ? "Ca Chiều" : "Ca Tối";
    IconData icon = shift.buoi == 'sang' ? Icons.wb_sunny : shift.buoi == 'chieu' ? Icons.wb_twighlight : Icons.nightlight_round;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWorking ? kLightCyanBg1 : kLightCyanBg2,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: isWorking ? kPrimaryColor.withOpacity(0.5) : kBorderCyan),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: isWorking ? kPrimaryColor : kGreyTextColor),
                  const SizedBox(width: 8),
                  Text(buoiLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isWorking ? kTextColor : kGreyTextColor)),
                ],
              ),
              Switch(
                value: isWorking,
                activeColor: kPrimaryColor,
                onChanged: (val) {
                  onShiftChanged(WeeklyScheduleItem(
                    thu: shift.thu, 
                    buoi: shift.buoi, 
                    gioBatDau: shift.gioBatDau, 
                    gioKetThuc: shift.gioKetThuc, 
                    trangThai: val ? 'lam' : 'nghi',
                  ));
                },
              )
            ],
          ),
          if (isWorking) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimePicker(context, "Từ", shift.gioBatDau, (newTime) {
                  onShiftChanged(WeeklyScheduleItem(
                    thu: shift.thu, 
                    buoi: shift.buoi, 
                    gioBatDau: newTime, 
                    gioKetThuc: shift.gioKetThuc, 
                    trangThai: shift.trangThai,
                  ));
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePicker(context, "Đến", shift.gioKetThuc, (newTime) {
                  onShiftChanged(WeeklyScheduleItem(
                    thu: shift.thu, 
                    buoi: shift.buoi, 
                    gioBatDau: shift.gioBatDau, 
                    gioKetThuc: newTime, 
                    trangThai: shift.trangThai,
                  ));
                })),
              ],
            )
          ]
        ],
      ),
    );
  }

  void _showGenerateSlotsPicker(BuildContext context, ScheduleConfigViewmodel viewModel) async {
    if (viewModel.currentConfig == null || viewModel.currentConfig!.weeklySchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng thiết lập và lưu ít nhất 1 lịch làm việc trước!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final DateTime today = DateTime.now();
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: today, 
        end: today.add(const Duration(days: 7))
      ),
      firstDate: today, 
      lastDate: today.add(const Duration(days: 90)), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor, 
              onPrimary: Colors.white, 
              onSurface: kTextColor, 
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      String startDateStr = "${pickedRange.start.year}-${pickedRange.start.month.toString().padLeft(2, '0')}-${pickedRange.start.day.toString().padLeft(2, '0')}";
      String endDateStr = "${pickedRange.end.year}-${pickedRange.end.month.toString().padLeft(2, '0')}-${pickedRange.end.day.toString().padLeft(2, '0')}";

      if (context.mounted) {
        await viewModel.generateSlots(startDateStr, endDateStr, context);
      }
    }
  }

  Widget _buildTimePicker(BuildContext context, String label, String timeStr, Function(String) onPicked) {
    return InkWell(
      onTap: () async {
        final parts = timeStr.split(':');
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
        );
        if (picked != null) {
          onPicked("${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorderCyan)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label: $timeStr", style: const TextStyle(fontSize: 14, color: kTextColor)),
            const Icon(Icons.access_time, size: 16, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  void _saveConfigForDay(int thu, List<WeeklyScheduleItem> newShiftsForDay, ScheduleConfigViewmodel viewModel) async {
    final currentConfig = viewModel.currentConfig;
    if (currentConfig == null) return;

    List<WeeklyScheduleItem> newWeekly = List.from(currentConfig.weeklySchedule);
    newWeekly.removeWhere((element) => element.thu == thu);
    newWeekly.addAll(newShiftsForDay);

    DoctorScheduleConfigModel newConfig = DoctorScheduleConfigModel(
      slotTime: currentConfig.slotTime,
      breakTime: currentConfig.breakTime,
      weeklySchedule: newWeekly,
    );

    bool success = await viewModel.saveScheduleConfig(newConfig);

    if (viewModel.scheduleConfigResult) {
      await viewModel.loadScheduleConfig();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Lưu cấu hình thành công!' : 'Lưu thất bại. Vui lòng thử lại.'),
        backgroundColor: success ? kPrimaryColor : Colors.red,
      ));
    }
  }

  void _openLeaveDialog(BuildContext context, ScheduleConfigViewmodel viewModel) {
    DateTime selectedDate = DateTime.now();
    String selectedBuoi = 'ca_ngay';
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Báo Nghỉ Đột Xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hệ thống sẽ khóa các ca khám trống và tự động HỦY các lịch hẹn bệnh nhân đã đặt trong thời gian này.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_calendar, color: kPrimaryColor),
                      title: Text("Ngày nghỉ: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: const TextStyle(color: kTextColor)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedBuoi,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Khung thời gian nghỉ', prefixIcon: Icon(Icons.timelapse, color: kPrimaryColor)),
                      items: const [
                        DropdownMenuItem(value: 'ca_ngay', child: Text('Cả ngày hôm đó')),
                        DropdownMenuItem(value: 'sang', child: Text('Buổi Sáng (Trước 12h)')),
                        DropdownMenuItem(value: 'chieu', child: Text('Buổi Chiều (12h - 18h)')),
                        DropdownMenuItem(value: 'toi', child: Text('Buổi Tối (Sau 18h)')),
                      ],
                      onChanged: (v) { if (v != null) setDialogState(() => selectedBuoi = v); },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reasonController,
                      style: const TextStyle(color: kTextColor),
                      decoration: const InputDecoration(labelText: 'Lý do báo nghỉ', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập lý do để báo cho bệnh nhân' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng', style: TextStyle(color: kGreyTextColor))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                      await viewModel.submitDoctorLeave(dateStr, selectedBuoi, reasonController.text, context);
                    }
                  },
                  child: const Text('Xác nhận nghỉ', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}