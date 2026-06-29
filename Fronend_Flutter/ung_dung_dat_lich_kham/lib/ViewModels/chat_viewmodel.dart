// lib/view_model/chat_view_model.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import '../Config/BASE_URL.dart'; 

class ChatViewModel extends ChangeNotifier {
  // Danh sách lưu trữ các tin nhắn hiển thị trên màn hình chat
  List<ChatMessage> messages = [];
  
  // Trạng thái chờ đợi phản hồi từ API Backend (true là đang load, false là xong)
  bool isLoading = false;
  
  // Biến lưu trữ mã phiên hội thoại giúp AI "có trí nhớ" xuyên suốt cuộc trò chuyện
  String? sessionToken;

  final String _baseUrl = '$BASE_URL/api/chatbot/ask'; 

  // Hàm xử lý logic gửi tin nhắn của người dùng lên hệ thống Backend
  Future<void> sendMessage(String text) async {
    // Nếu người dùng chỉ gõ dấu cách hoặc không nhập gì thì bỏ qua, không gửi
    if (text.trim().isEmpty) return;

    // 1. Cập nhật UI: Thêm ngay tin nhắn của Bệnh nhân (isUser: true) lên màn hình
    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    notifyListeners(); // Thông báo cho View (giao diện) biết để vẽ lại bong bóng chat mới

    // 2. Đóng gói dữ liệu (Payload) dưới dạng Map để chuẩn bị gửi lên Server
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ưu tiên tìm key 'ma_nguoi_dung' giống hệt logic trong AuthViewModel của bạn
      String? realUserId = prefs.getString('ma_nguoi_dung');
      
      // Nếu không có, dự phòng tìm 'userId'
      if (realUserId == null) {
        int? intId = prefs.getInt('userId');
        if (intId != null) {
          realUserId = intId.toString();
        }
      }

      // Đóng gói Payload gửi lên Node.js
      Map<String, dynamic> bodyData = {
        'message': text,
        // Dùng ID thật đã lấy được. Nếu rỗng (chưa đăng nhập), truyền cờ an toàn "guest"
        'userId': realUserId ?? "guest", 
      };
      
      // Kiểm tra "trí nhớ": Nếu có sessionToken từ các câu chat trước, đính kèm vào body luôn
      if (sessionToken != null) {
        bodyData['session_token'] = sessionToken;
      }

      // 3. Tiến hành gọi API bằng phương thức POST
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'}, // Định dạng dữ liệu truyền đi là JSON
        body: jsonEncode(bodyData), // Chuyển đổi Map thành chuỗi JSON chuẩn
      );

      // 4. Kiểm tra mã phản hồi (HTTP Status Code) từ Server
      if (response.statusCode == 200) {
        // Giải mã chuỗi JSON nhận được từ Node.js thành Map trong Dart
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Lưu lại session_token được Backend trả về để dùng cho các câu hỏi tiếp theo
          sessionToken = data['session_token'];
          
          // Thêm tin nhắn phản hồi của AI (isUser: false) vào danh sách hiển thị
          messages.add(ChatMessage(text: data['reply'], isUser: false));
        } else {
          // Trường hợp Backend chạy nhưng trả về success: false (lỗi logic bên trong)
          messages.add(ChatMessage(text: "Lỗi hệ thống: ${data['message']}", isUser: false));
        }
      } else {
        // Trường hợp Server trả về các mã lỗi như 404, 500, 429...
        messages.add(ChatMessage(text: "Lỗi kết nối: Phản hồi không hợp lệ từ máy chủ (${response.statusCode}).", isUser: false));
      }
    } catch (e) {
      // Bắt các lỗi mất mạng mạng, rớt kết nối hoặc sai IP không thể chọc tới Server
      messages.add(ChatMessage(text: "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.", isUser: false));
      print("Lỗi call API Chatbot: $e");
    } finally {
      // 5. Kết thúc luồng xử lý: Tắt hiệu ứng chờ và cập nhật giao diện lần cuối
      isLoading = false;
      notifyListeners();
    }
  }
}