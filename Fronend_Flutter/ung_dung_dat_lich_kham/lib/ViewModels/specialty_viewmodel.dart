import 'package:flutter/material.dart';
import '../Models/specialtyModel.dart';
import '../Services/specialty_service.dart';

class SpecialtyViewModel extends ChangeNotifier {
  final APISpecialtyService _apiService = APISpecialtyService();

  List<SpecialtyModel>? _listSpecialty;
  bool _isLoading = false;
  String _errorMessage = '';

  List<SpecialtyModel>? get listSpecialty => _listSpecialty;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadAllSpecialties() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _listSpecialty = await _apiService.getAllSpecialties();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}