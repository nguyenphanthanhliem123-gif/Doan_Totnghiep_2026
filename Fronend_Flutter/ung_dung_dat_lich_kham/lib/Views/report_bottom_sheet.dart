import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Constants/ui_constants.dart'; 
import '../Config/BASE_URL.dart'; // Đảm bảo đường dẫn này đúng với project của bạn

class ReportBottomSheet extends StatefulWidget {
  final int targetId;
  final String targetName;
  final String targetType; // Ví dụ: 'Doctor' hoặc 'Patient'

  const ReportBottomSheet({
    super.key,
    required this.targetId,
    required this.targetName,
    required this.targetType,
  });

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReport() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do báo cáo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Lấy token của User đang đăng nhập

      final res = await http.post(
        Uri.parse('$BASE_URL/api/profile/report'), // API Backend ta sẽ tạo ở Bước 3
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reportedId': widget.targetId,
          'reportedType': widget.targetType,
          'reason': _reasonController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Đóng BottomSheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi báo cáo thành công. Quản trị viên sẽ xem xét!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Lỗi từ server');
      }
    } catch (e) {
      debugPrint('Lỗi gửi report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại sau!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Đẩy lên khi bàn phím xuất hiện
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Báo cáo ${widget.targetType == 'Doctor' ? 'Bác sĩ' : 'Người dùng'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                const TextSpan(text: 'Bạn đang báo cáo: '),
                TextSpan(
                  text: widget.targetName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Vui lòng cung cấp chi tiết lý do bạn báo cáo:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Bác sĩ không tham gia cuộc gọi, thái độ không tốt, spam...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _submitReport,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Gửi báo cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}