import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Services/healthRecord_service.dart';
import '../Models/health_record_model.dart';

class HealthRecordViewModel extends ChangeNotifier {
  final APIHealRecordService _apiHealRecordService = APIHealRecordService();
  
  HealthRecordModel? _recordModel;
  List<HealthRecordModel>? _listRecord;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _addRecordResult = false;

  bool get addRecordResult => _addRecordResult;
  HealthRecordModel? get record => _recordModel;
  List<HealthRecordModel>? get listRecord => _listRecord;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadHealthRecord() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _listRecord = await _apiHealRecordService.getAllHealthRecordByUserID();
    }
    catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRelativeRecord({
    required String tenNguoiThan,
    required String moiQuanHe,
    required DateTime birthDay,
    required int gender,
    required String address,
    String? nhomMau,
    String? diUng,
    String? benhNen,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _addRecordResult = false;
    notifyListeners();

    try {
      _addRecordResult = await _apiHealRecordService.addRelativeRecord(
        tenNguoiThan: tenNguoiThan,
        moiQuanHe: moiQuanHe,
        birthDay: birthDay,
        gender: gender,
        address: address,
        nhomMau: nhomMau,
        diUng: diUng,
        benhNen: benhNen,
      );

      // Nếu thêm thành công, gọi lại hàm fetch data để cập nhật danh sách
      if (_addRecordResult == true) {
        await loadHealthRecord(); // (Hàm _loadHealthRecord bạn đã đổi tên trước đó)
      }
    } catch (e) {
      _errorMessage = e.toString();
      _addRecordResult = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}