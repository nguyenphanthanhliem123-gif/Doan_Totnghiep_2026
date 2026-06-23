import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Services/clinic_service.dart';

class DoctorClinicViewmodel extends ChangeNotifier {
  APIClinicService _apiClinicService = APIClinicService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool? _updateClinicForDoctorResult;
  bool? get updateClinicForDoctorResult => _updateClinicForDoctorResult;

  Future<void> updateClinicForDoctor(List<Map<String, dynamic>> listClinic) async {
    _isLoading = true;
    _errorMessage = '';
    _updateClinicForDoctorResult = false;
    notifyListeners();

    try{
      _updateClinicForDoctorResult = await _apiClinicService.updateClinicsForDoctor(listClinic);
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners(); 
    }
  }
}