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

  bool _updateRecordResult = false;
  bool get updateRecordResult => _updateRecordResult;

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


  Future<void> updateRecord({
    required int maBenhNhan,
    required String tenHoSo,
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
    _updateRecordResult = false;
    notifyListeners();

    try {
      _updateRecordResult = await _apiHealRecordService.updateHealthRecord(
        maBenhNhan: maBenhNhan,
        tenHoSo: tenHoSo,
        moiQuanHe: moiQuanHe,
        birthDay: birthDay,
        gender: gender,
        address: address,
        nhomMau: nhomMau,
        diUng: diUng,
        benhNen: benhNen,
      );

      // Nếu cập nhật thành công, gọi API kéo lại danh sách mới nhất
      if (_updateRecordResult == true) {
        await loadHealthRecord(); 
        
        // Cập nhật luôn cục dữ liệu đang chọn để màn hình chi tiết đổi theo
        if (_recordModel != null) {
           _recordModel = _listRecord?.firstWhere((element) => element.id == maBenhNhan, orElse: () => _recordModel!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _updateRecordResult = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetailRecord(int maBenhNhan) async {
    _isLoading = true;
    _errorMessage = '';
    _recordModel = null; // Xóa dữ liệu cũ đi để tránh hiển thị nhầm hồ sơ trước đó
    notifyListeners();

    try {
      _recordModel = await _apiHealRecordService.getDetailHealthRecord(maBenhNhan);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}