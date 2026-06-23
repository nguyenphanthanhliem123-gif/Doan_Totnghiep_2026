import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/models/review_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/review_viewmodel.dart';

// --- GIAO DIỆN CHÍNH ---
class ReviewsDoctorScreen extends StatefulWidget {
  final int doctorID;

  const ReviewsDoctorScreen({super.key, required this.doctorID});

  @override
  State<ReviewsDoctorScreen> createState() => _ReviewsDoctorScreenState();
}

class _ReviewsDoctorScreenState extends State<ReviewsDoctorScreen> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ReviewViewModel>().fetchReviews(widget.doctorID);
    });
    super.initState();
  }


  String formatDateTime(String? dateStr) {
    if (dateStr == null) return "Chưa rõ";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      
      // Định dạng ngày, giờ, phút có chèn số 0 ở trước nếu < 10
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0'); // Thêm padLeft cho tháng nếu muốn đồng bộ
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute - $day Tháng $month, ${date.year}';
    } catch (e) {
      return "Chưa rõ";
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewVM = context.watch<ReviewViewModel>();
    final reviews = reviewVM.reviews;
    print(reviews);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đánh giá từ bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: reviewVM.isLoading
      ? Center(child: CircularProgressIndicator(),)
      : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Phần tổng quan điểm số
          SliverToBoxAdapter(
            child: _buildOverallRating(reviews, reviewVM.averageRating),
          ),
          
          // Danh sách các bình luận
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildReviewCard(reviews[index]);
                },
                childCount: reviews.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: TỔNG QUAN ĐIỂM SỐ ---
  Widget _buildOverallRating(List<ReviewModel> listRV, double averageRating) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cột điểm số
          Column(
            children: [
              Text(
                averageRating.toString(),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 5),
              _buildStarRating(averageRating, size: 18),
              const SizedBox(height: 8),
              Text(
                'Dựa trên ${listRV.length} đánh giá',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: THẺ ĐÁNH GIÁ (REVIEW CARD) ---
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thẻ: Avatar + Tên + Ngày
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(review.patientAvatar ?? 'https://cdn-icons-png.flaticon.com/512/4320/4320337.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(review.createdAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Số sao ở góc phải
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),

          // Nội dung đánh giá
          Text(
            review.content,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: HÀM VẼ NGÔI SAO ---
  Widget _buildStarRating(double rating, {double size = 16}) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star_rounded, color: Colors.orange, size: size);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half_rounded, color: Colors.orange, size: size);
        } else {
          return Icon(Icons.star_outline_rounded, color: Colors.grey.shade300, size: size);
        }
      }),
    );
  }
}