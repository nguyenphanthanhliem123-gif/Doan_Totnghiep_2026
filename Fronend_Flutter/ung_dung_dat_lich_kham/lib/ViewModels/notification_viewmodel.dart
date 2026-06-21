import 'package:flutter/material.dart';
import 'package:ung_dung_dat_lich_kham/Models/notification_model.dart';
import 'package:ung_dung_dat_lich_kham/Services/notification_service.dart';

class NotificationViewmodel extends ChangeNotifier {
  final APINotificationService _apiNotificationService = APINotificationService();

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel>? _listNotification;
  bool? _markOne;

  bool get isLoading => _isLoading;
  String? get errotMessage => _errorMessage;
  List<NotificationModel>? get listNotification => _listNotification;
  bool? get markOne => _markOne;

  Future<void> getAllNotification()async{
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _listNotification = await _apiNotificationService.fecthAllNotificationByID();
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }

  }

  Future<void> maekOne(notificationID)async{
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try{
      _markOne = await _apiNotificationService.markOne(notificationID);
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }

  }
}