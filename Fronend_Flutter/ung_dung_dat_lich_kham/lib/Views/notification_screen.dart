import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/notification_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/notification_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/Views/review_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách thông báo ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewmodel>().getAllNotification();
    });
  }

  // Hàm xử lý vuốt màn hình để làm mới dữ liệu (Pull to refresh)
  Future<void> _refreshData() async {
    await context.read<NotificationViewmodel>().getAllNotification();
  }

  // Hàm hỗ trợ định dạng hiển thị thời gian đơn giản (HH:mm dd/MM/yyyy)
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$hour:$minute $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi trạng thái từ NotificationViewmodel
    final viewModel = context.watch<NotificationViewmodel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _buildBody(viewModel),
    );
  }

  // Hàm điều hướng hiển thị Body dựa theo các trạng thái của ViewModel
  Widget _buildBody(NotificationViewmodel viewModel) {
    // 1. Nếu đang tải dữ liệu lần đầu (chưa có danh sách)
    if (viewModel.isLoading && viewModel.listNotification == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Nếu xảy ra lỗi từ API
    if (viewModel.errotMessage != null && viewModel.errotMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Có lỗi xảy ra: ${viewModel.errotMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Nếu danh sách trống
    if (viewModel.listNotification == null || viewModel.listNotification!.isEmpty) {
      return _buildEmptyState();
    }

    // 4. Hiển thị danh sách thông báo khi dữ liệu đã sẵn sàng
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: viewModel.listNotification!.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.transparent),
        itemBuilder: (context, index) {
          final noti = viewModel.listNotification![index];
          return _buildNotificationItem(noti);
        },
      ),
    );
  }

  // Giao diện khi không có thông báo nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa có thông báo nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Giao diện cho từng item thông báo cụ thể
  Widget _buildNotificationItem(NotificationModel noti) {
    IconData iconData;
    Color iconColor;
    Color bgColor;
    String displayTitle;

    switch (noti.type) {
      case 'Xac_nhan':
      case 'Xác nhận lịch hẹn':
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        displayTitle = 'Xác nhận lịch hẹn';
        break;
      case 'Tu_choi':
      case 'Từ chối lịch hẹn':
        iconData = Icons.remove_circle_rounded;
        iconColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        displayTitle = 'Từ chối lịch hẹn';
        break;
      case 'Huy_lich':
      case 'Hủy lịch hẹn':
        iconData = Icons.cancel_rounded;
        iconColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        displayTitle = 'Hủy lịch hẹn';
        break;
      case 'Nhac_nho':
      case 'Nhắc nhở lịch hẹn':
        iconData = Icons.access_alarm_rounded;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
        displayTitle = 'Nhắc nhở lịch hẹn';
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        iconColor = Colors.teal;
        bgColor = Colors.teal.withOpacity(0.1);
        displayTitle = 'Thông báo hệ thống';
    }

    final bool isRead = noti.status == 1? true: false; 

    return Material(
      color: isRead ? Colors.white : const Color(0xFFF0F7FF),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await context.read<NotificationViewmodel>().maekOne(noti.notificationID);
            await context.read<NotificationViewmodel>().getAllNotification();
          }

          // Chuyển hướng nếu là thông báo Đánh giá
          if (noti.type == 'Đánh giá') {
            // Dùng Regex bóc tách ID lịch hẹn từ chuỗi "[ID 5]..."
            final match = RegExp(r'\[ID (\d+)\]').firstMatch(noti.content);
            if (match != null) {
              final appointmentId = int.parse(match.group(1)!);
              
              // Chuyển sang màn hình Đánh giá
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewScreen(
                    appointmentId: appointmentId,
                  ),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Khối Icon hiển thị theo trạng thái tương ứng
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              
              // 2. Khối nội dung text lấy từ Model
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      noti.content, 
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isRead ? Colors.grey[600] : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(noti.date), 
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. Chấm tròn màu xanh báo hiệu thông báo "Chưa đọc"
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  height: 9,
                  width: 9,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}