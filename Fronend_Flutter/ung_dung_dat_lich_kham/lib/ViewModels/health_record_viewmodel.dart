import 'package:flutter/material.dart';
import '../Models/health_record_model.dart';

class HealthRecordViewModel extends ChangeNotifier {
  // Dữ liệu mẫu ban đầu
  final HealthRecordModel _record = HealthRecordModel(
    height: '169',
    weight: '67',
    bloodType: 'AB +',
    gender: 'Nữ',
  );

  HealthRecordModel get record => _record;

  // Cập nhật thông tin cơ bản (Màn hình 3-B)
  void updateBasicInfo(String height, String weight, String blood, String gender) {
    _record.height = height;
    _record.weight = weight;
    _record.bloodType = blood;
    _record.gender = gender;
    notifyListeners();
  }

  // Cập nhật ghi chú sức khỏe (Màn hình 3-G)
  void updateNotes(String condition, String notes) {
    _record.currentCondition = condition;
    _record.personalNotes = notes;
    notifyListeners();
  }
}