import 'package:flutter/material.dart';
import '../Services/bookingService.dart';
import 'package:ung_dung_dat_lich_kham/Models/doctor_schedule_model.dart';


class ScheduleViewModel extends ChangeNotifier {
  final APIBookingService _service = APIBookingService();
  
  List<DoctorScheduleModel>? _schedules = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<DoctorScheduleModel>? get schedules => _schedules;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadDoctorSchedules(String date) async {
    print(date);
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _schedules = await _service.FecthDoctorSchedule(date);
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners(); // Cập nhật lại UI cho Frontend
    }
  }
}