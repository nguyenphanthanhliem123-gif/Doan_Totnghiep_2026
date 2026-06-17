import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Models/paymentModel.dart';
import 'package:ung_dung_dat_lich_kham/Services/payment_service.dart';

class PaymentViewmodel extends ChangeNotifier{
  final APIPaymentService _apiPaymentService = APIPaymentService();

  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentModel>? _listPayment;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PaymentModel>? get listPayment => _listPayment;

  Future<void> fetchPaymentHistory() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _listPayment = await _apiPaymentService.fetchHistory();
    }
    catch(e){
      _errorMessage = e.toString();
    }
    finally{
      _isLoading = false;
      notifyListeners();
    }
  }
}