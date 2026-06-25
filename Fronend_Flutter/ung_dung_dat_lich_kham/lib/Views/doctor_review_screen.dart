import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/review_viewmodel.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đồng bộ UI Constants

class DoctorReviewScreen extends StatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  @override
  void initState() {
    super.initState();
  }

  String formatDateStr(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Gần đây";
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewVM = context.watch<ReviewViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đánh Giá & Nhận Xét",
          style: kHeaderTextStyle, // 🌟 Text Style chuẩn
        ),
      ),
      body: reviewVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              children: [
                // ==========================================
                // PHẦN 1: BẢNG THỐNG KÊ TỔNG QUAN RATING
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(kDefaultPadding), // Lề 20
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  reviewVM.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: kTextColor),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Tổng số bình luận",
                                  style: TextStyle(color: kGreyTextColor.withOpacity(0.8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildRatingBar(5, reviewVM.ratingDistribution[5] ?? 0.0),
                                _buildRatingBar(4, reviewVM.ratingDistribution[4] ?? 0.0),
                                _buildRatingBar(3, reviewVM.ratingDistribution[3] ?? 0.0),
                                _buildRatingBar(2, reviewVM.ratingDistribution[2] ?? 0.0),
                                _buildRatingBar(1, reviewVM.ratingDistribution[1] ?? 0.0),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(reviewVM, 0, "Tất cả"),
                            _buildFilterChip(reviewVM, 5, "5 Sao"),
                            _buildFilterChip(reviewVM, 4, "4 Sao"),
                            _buildFilterChip(reviewVM, 3, "3 Sao"),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // ==========================================
                // PHẦN 2: DANH SÁCH BÌNH LUẬN THỰC TẾ
                // ==========================================
                Expanded(
                  child: reviewVM.reviews.isEmpty
                      ? const Center(child: Text("Không có đánh giá nào phù hợp.", style: TextStyle(color: kGreyTextColor)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(kDefaultPadding), // Lề 20
                          itemCount: reviewVM.reviews.length,
                          separatorBuilder: (context, index) => const Divider(height: 30, color: kBorderCyan), // Đường viền chuẩn
                          itemBuilder: (context, index) {
                            final review = reviewVM.reviews[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: (review.patientAvatar != null && review.patientAvatar!.isNotEmpty)
                                      ? NetworkImage(review.patientAvatar!)
                                      : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
                                ),
                                const SizedBox(width: 15),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            review.patientName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextColor),
                                          ),
                                          Text(
                                            formatDateStr(review.createdAt),
                                            style: const TextStyle(color: kGreyTextColor, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: List.generate(
                                          5, 
                                          (starIndex) => Icon(
                                            Icons.star, 
                                            color: starIndex < review.rating ? Colors.amber : Colors.grey.shade300, 
                                            size: 14
                                          )
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        review.content,
                                        style: const TextStyle(color: kTextColor, height: 1.5, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$star", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kGreyTextColor)),
          const SizedBox(width: 5),
          const Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: kLightCyanBg1, // Màu nền của thanh
                color: kPrimaryColor, // Màu chạy phần trăm chuẩn
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ReviewViewModel vm, int id, String label) {
    final isSelected = vm.selectedFilter == id;
    return GestureDetector(
      onTap: () => vm.filterReviews(id),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          border: Border.all(color: isSelected ? kPrimaryColor : kBorderCyan),
          borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo 20
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}