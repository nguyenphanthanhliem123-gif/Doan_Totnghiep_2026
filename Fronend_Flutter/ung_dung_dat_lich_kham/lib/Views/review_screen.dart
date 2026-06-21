import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/appointment_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/review_viewmodel.dart'; // 🚀 1. Thêm import ReviewViewModel

class ReviewScreen extends StatefulWidget {
  final int appointmentId;

  const ReviewScreen({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5; // Mặc định 5 sao
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentViewModel>().fetchDetail(widget.appointmentId);
    });
    super.initState();
  }

  // 🚀 2. Cập nhật hàm xử lý Gửi đánh giá thực tế
  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    
    // Gọi sang ReviewViewModel để gửi dữ liệu lên Backend
    final reviewVM = context.read<ReviewViewModel>();
    await reviewVM.createReviewFuture(
      widget.appointmentId, 
      _rating, 
      _commentController.text.trim(),
    );
    
    setState(() => _isSubmitting = false);

    if (mounted) {
      // Kiểm tra nếu có lỗi xảy ra từ Backend (Ví dụ: Lịch hẹn chưa xong, hoặc đã đánh giá rồi)
      if (reviewVM.errorMessage != null && reviewVM.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewVM.errorMessage!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } 
      // Nếu thành công (createReview == true)
      else if (reviewVM.createReview == true) {
        // Hiển thị Dialog cảm ơn
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text('Cảm ơn bạn!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Đánh giá của bạn giúp chúng tôi cải thiện chất lượng dịch vụ tốt hơn.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Đóng Dialog
                      Navigator.pop(context); // Quay về màn thông báo/lịch sử lịch hẹn
                    },
                    child: const Text('Đóng', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        // Trường hợp không có lỗi nhưng phản hồi không xác định
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh giá không thành công. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentVM = context.watch<AppointmentViewModel>();
    final appointmentDetail = appointmentVM.appointmentDetail;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Đánh giá Bác sĩ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: appointmentVM.isLoading && appointmentDetail == null
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ảnh đại diện giả lập
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 4),
                image: const DecorationImage(
                  image: NetworkImage('https://cdn-icons-png.flaticon.com/512/3774/3774299.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ca khám với ${appointmentDetail?.doctorName ?? "Bác sĩ"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cảm thấy chất lượng dịch vụ như thế nào?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Khối Đánh giá Sao
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: index < _rating ? Colors.amber : Colors.grey.shade400,
                        size: 48,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _getRatingText(_rating),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 32),

            // Khung nhập nhận xét
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn (Tùy chọn)...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Nút Gửi
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gửi Đánh Giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm phụ trợ đổi chữ theo số sao
  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return "Rất tệ";
      case 2: return "Tệ";
      case 3: return "Bình thường";
      case 4: return "Tốt";
      case 5: return "Tuyệt vời!";
      default: return "";
    }
  }
}