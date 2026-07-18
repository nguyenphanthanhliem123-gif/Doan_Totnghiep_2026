import 'package:flutter/material.dart';
import '../Constants/ui_constants.dart';

class AppointmentActionHelper {
  
  // Nút Action Hình Vuông Dọc (Dùng ở danh sách)
  static Widget buildActionBtn({required IconData icon, required String text, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusSmall), 
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              text, 
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // Nút Action Outline Ngang (Dùng ở chi tiết)
  static Widget buildOutlinedButton(String text, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color, 
        side: BorderSide(color: color), 
        padding: const EdgeInsets.symmetric(vertical: 12), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall))
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // Nút Action Đặc Ngang (Dùng ở chi tiết)
  static Widget buildSolidButton(String text, IconData icon, Color bgColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor, 
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(vertical: 12), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)), 
        elevation: 0
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // Dialog hủy lịch cho bệnh nhân (Thêm logic bỏ qua check giờ nếu là ca Chờ dời lịch)
  static void showPatientCancelDialog({
    required BuildContext context, 
    required DateTime startTime, 
    required String currentStatus, 
    required Future<void> Function() onConfirm
  }) {
    // Nếu bệnh nhân chủ động hủy ca bình thường -> Check 2 tiếng
    if (currentStatus != 'reschedule_pending') {
      final now = DateTime.now();
      final difference = startTime.difference(now);
      if (difference.inHours < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không thể hủy! Bạn chỉ được phép hủy lịch khám trước giờ bắt đầu ít nhất 2 tiếng.'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận hủy lịch', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn khám này không? \n\n'
          '⚠️ LƯU Ý: Nếu bạn đã thanh toán trực tuyến, số tiền sẽ KHÔNG ĐƯỢC HOÀN LẠI theo chính sách của phòng khám.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 
              await onConfirm();
            },
            child: const Text('Đồng ý hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Dialog báo bận cho bác sĩ
  static void showDoctorCancelDialog({
    required BuildContext context, 
    required Future<void> Function() onConfirm
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Báo bận đột xuất', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Bạn có chắc chắn muốn hủy ca khám này không?\n\nHệ thống sẽ tự động xử lý bảo lưu tiền (nếu có) và yêu cầu bệnh nhân dời lịch sang giờ khác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); 
              await onConfirm();
            },
            child: const Text('Xác nhận báo bận', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}