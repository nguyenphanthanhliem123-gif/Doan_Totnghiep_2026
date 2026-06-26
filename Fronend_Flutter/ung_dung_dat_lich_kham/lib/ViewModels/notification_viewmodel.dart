import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ung_dung_dat_lich_kham/Config/BASE_URL.dart';
import 'package:ung_dung_dat_lich_kham/Models/notification_model.dart';
import 'package:ung_dung_dat_lich_kham/Services/notification_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationViewmodel extends ChangeNotifier {
  final APINotificationService _apiNotificationService = APINotificationService();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel>? _listNotification;
  bool? _markOne;
  int _notiUnRead = 0;

  bool get isLoading => _isLoading;
  String? get errotMessage => _errorMessage;
  List<NotificationModel>? get listNotification => _listNotification;
  bool? get markOne => _markOne;
  int get notiUnRead => _notiUnRead; 

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

  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    _errorMessage = '';
    _notiUnRead;
    notifyListeners();

    try{
      _notiUnRead = await _apiNotificationService.fecthUnReadCount();
    }catch(e){
      _errorMessage = e.toString();
    }finally{
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Hàm khởi tạo kết nối Socket
  void initSocket() async {
    if (_socket != null && _socket!.connected) return; // Nếu đã kết nối rồi thì bỏ qua

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if(token == null ) return;

    // Gọi API lấy số lượng ban đầu
    fetchUnreadCount();

    // Thay URL_BACKEND bằng địa chỉ IP server của bạn
    _socket = IO.io(BASE_URL, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setAuth({'token': token})
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('✅ Socket.IO đã kết nối thành công từ ViewModel');
      // Đăng ký định danh user với backend
      _socket!.emit('register', token);
    });

    // 🌟 LẮNG NGHE SỰ KIỆN TỪ BACKEND
    _socket!.on('new_notification', (data) {
      debugPrint('🔔 Nhận tín hiệu thông báo mới qua Socket');
      
      // Cách 1: Gọi lại API để cập nhật số lượng chính xác nhất từ DB
      fetchUnreadCount();

      // Cách 2: Hoặc tự cộng dồn trực tiếp ở local nếu không muốn gọi API liên tục
      //_notiUnRead++;
      notifyListeners(); 
    });

    _socket!.onDisconnect((_) => debugPrint('❌ Mất kết nối Socket'));
  }

  // 3. Hàm ngắt kết nối khi user đăng xuất
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}