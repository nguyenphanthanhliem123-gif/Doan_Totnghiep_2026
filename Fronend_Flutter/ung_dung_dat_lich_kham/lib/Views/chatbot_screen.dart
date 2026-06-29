// lib/views/chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/chat_viewmodel.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Bộ điều khiển ô nhập văn bản
  final TextEditingController _textController = TextEditingController();
  // Bộ điều khiển danh sách cuộn (để tự động cuộn xuống khi có tin mới)
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm bổ trợ: Tự động cuộn màn hình xuống dưới cùng khi xuất hiện tin nhắn mới
  void _scrollToBottom() {
    // WidgetsBinding giúp đợi giao diện render xong tin nhắn mới rồi mới cuộn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), // Thời gian cuộn 0.3 giây
          curve: Curves.easeOut, // Hiệu ứng cuộn mượt mà
        );
      }
    });
  }

  // Hàm xử lý khi người dùng nhấn nút Gửi tin nhắn
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      // Gọi hàm sendMessage từ ChatViewModel thông qua Provider (read vì không cần lắng nghe thay đổi ở đây)
      context.read<ChatViewModel>().sendMessage(text);
      _textController.clear(); // Xóa chữ trong ô nhập sau khi gửi
      _scrollToBottom(); // Cuộn giao diện xuống
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi dữ liệu từ ChatViewModel (mảng messages, biến isLoading)
    final chatVM = context.watch<ChatViewModel>();
    final Color primaryCyan = kPrimaryColor; // Màu xanh Cyan chủ đạo giống trang chủ

    // Kích hoạt cuộn xuống dưới cùng mỗi khi ViewModel cập nhật danh sách tin nhắn hoặc trạng thái loading
    _scrollToBottom();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám nhạt giúp nổi bật các bong bóng chat
      appBar: AppBar(
        title: const Text(
          'Trợ lý ảo MedCare AI', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KHU VỰC 1: HIỂN THỊ DANH SÁCH BONG BÓNG CHAT
            Expanded(
              child: chatVM.messages.isEmpty && !chatVM.isLoading
                  ? _buildEmptyState(primaryCyan) // Hiển thị màn hình chào nếu chưa có tin nhắn nào
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      // Nếu AI đang load thì cộng thêm 1 item ở cuối để hiển thị bong bóng "đang gõ"
                      itemCount: chatVM.messages.length + (chatVM.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Nếu đi đến cuối danh sách và AI đang xử lý, hiển thị hiệu ứng chờ
                        if (index == chatVM.messages.length && chatVM.isLoading) {
                          return _buildChatBubble("AI đang phân tích...", false, isLoading: true);
                        }

                        // Lấy từng tin nhắn trong mảng ra để vẽ giao diện
                        final message = chatVM.messages[index];
                        return _buildChatBubble(message.text, message.isUser);
                      },
                    ),
            ),
            
            // KHU VỰC 2: THANH NHẬP LIỆU (INPUT BAR) Ở DƯỚI CÙNG MÀN HÌNH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2), // Đổ bóng nhẹ lên phía trên thanh nhập liệu
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ô nhập văn bản
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send, // Đổi nút Enter bàn phím thành nút Send
                      onSubmitted: (_) => _handleSend(), // Nhấn Enter trên bàn phím cũng gửi tin
                      decoration: InputDecoration(
                        hintText: 'Hỏi về chuyên khoa, quy trình khám...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none, // Ẩn viền thô cứng đi
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Nút hình tròn gửi tin nhắn
                  CircleAvatar(
                    backgroundColor: primaryCyan,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM TẠO GIAO DIỆN BONG BÓNG CHAT (CHAT BUBBLE)
  Widget _buildChatBubble(String text, bool isUser, {bool isLoading = false}) {
    return Align(
      // Nếu là người dùng gửi thì đẩy sang PHẢI, nếu là AI thì đẩy sang TRÁI
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78, // Chiều ngang tối đa 78% màn hình
        ),
        decoration: BoxDecoration(
          // Người dùng: Nền xanh chữ trắng. AI: Nền trắng chữ đen xám.
          color: isUser ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),  // Bo góc đặc trưng cho bong bóng bên trái
            bottomRight: Radius.circular(isUser ? 4 : 16), // Bo góc đặc trưng cho bong bóng bên phải
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 35,
                child: Center(
                  child: LinearProgressIndicator(minHeight: 2, color: kPrimaryColor), // Thanh chạy chạy khi AI đang nghĩ
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  height: 1.35, // Giúp khoảng cách giữa các dòng chữ thoáng, dễ đọc
                ),
              ),
      ),
    );
  }

  // HÀM TẠO GIAO DIỆN MÀN HÌNH CHÀO TRỐNG (KHI CHƯA CHAT CÂU NÀO)
  Widget _buildEmptyState(Color primaryCyan) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_outlined, size: 60, color: primaryCyan), // Icon não bộ công nghệ AI
              ),
              const SizedBox(height: 16),
              const Text(
                'Tư vấn Sức khỏe thông minh AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy đặt câu hỏi về triệu chứng hoặc chuyên khoa cần khám. Trợ lý ảo MedCare sẽ phân tích dữ liệu phòng khám để gợi ý bác sĩ tốt nhất cho bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}