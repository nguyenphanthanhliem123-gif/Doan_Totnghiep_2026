import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Models/schedule_config_model.dart';
import 'package:ung_dung_dat_lich_kham/Services/schedule_confid_service.dart';

class ScheduleConfigViewmodel extends ChangeNotifier{
  final APIScheduleConfig _apiScheduleConfig = APIScheduleConfig();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _scheduleConfigResult = false;
  bool get scheduleConfigResult => _scheduleConfigResult;

  DoctorScheduleConfigModel? _currentConfig;
  DoctorScheduleConfigModel? get currentConfig => _currentConfig;

  // Lấy dữ liệu cấu hình
  Future<void> loadScheduleConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentConfig = await _apiScheduleConfig.getScheduleConfig();
      
      // Nếu chưa có cấu hình nào trong DB, khởi tạo giá trị rỗng mặc định
      _currentConfig ??= DoctorScheduleConfigModel(
          slotTime: 20, breakTime: 5, maxPatients: 30, weeklySchedule: []);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveScheduleConfig(DoctorScheduleConfigModel config) async {
  _isLoading = true;
  _errorMessage = '';
  _scheduleConfigResult = false;
  notifyListeners();

  try {
    _scheduleConfigResult = await _apiScheduleConfig.saveScheduleConfig(config);
    return _scheduleConfigResult;
  } catch (e) {
    _errorMessage = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // Helper lấy danh sách ca làm việc theo ngày (Thứ 2 -> Chủ Nhật)
  List<WeeklyScheduleItem> getShiftsForDay(int thu) {
    if (_currentConfig == null) return [];
    return _currentConfig!.weeklySchedule.where((element) => element.thu == thu).toList();
  }

  // Hàm gọi API phát sinh lịch khám tự động
  Future<bool> generateSlots(String startDate, String endDate, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiScheduleConfig.generateDoctorSlots(startDate, endDate);
      
      _isLoading = false;
      notifyListeners();

      if (result['succeeded'] == true) {
        // Hiển thị thông báo thành công (Có kèm số lượng slot được tạo)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Phát sinh lịch thành công!'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 4),
        ));
        return true;
      } else {
        // Báo lỗi từ Backend
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Có lỗi xảy ra.'),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không thể kết nối đến máy chủ.'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }
}