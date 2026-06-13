import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_detail_screen.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../Models/doctor_model.dart';

class DoctorListScreen extends StatefulWidget {
  final int? specialtyId;
  final String? specialtyName;

  const DoctorListScreen({super.key, this.specialtyId, this.specialtyName});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().loadDoctors(specialtyId: widget.specialtyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.specialtyName != null ? 'Bác sĩ ${widget.specialtyName}' : 'Danh Sách Bác Sĩ',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: doctorVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : doctorVM.errorMessage.isNotEmpty
              ? Center(child: Text(doctorVM.errorMessage, style: const TextStyle(color: Colors.red)))
              : doctorVM.listDoctor == null || doctorVM.listDoctor!.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: doctorVM.listDoctor!.length,
                      itemBuilder: (context, index) {
                        return _buildDoctorCard(doctorVM.listDoctor![index]);
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có bác sĩ nào trong chuyên khoa này.', style: TextStyle(color: kGreyTextColor)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return InkWell(
      onTap: () {
        if(!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doctor.id,))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh đại diện Bác sĩ
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 85,
                height: 100,
                color: kPrimaryColor.withOpacity(0.1),
                child: doctor.avatar != null && doctor.avatar!.isNotEmpty
                    ? Image.network(doctor.avatar!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: kPrimaryColor, size: 40))
                    : const Icon(Icons.person, color: kPrimaryColor, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            
            // 2. Thông tin chi tiết
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên và Học vị (Ví dụ: Thạc sĩ - Bác sĩ Nguyễn Văn A)
                  Text(
                    '${doctor.degree ?? "BS."} ${doctor.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Tên chuyên khoa (Màu chủ đạo)
                  Text(
                    doctor.specialtyName,
                    style: const TextStyle(fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  // Năm kinh nghiệm
                  Row(
                    children: [
                      const Icon(Icons.work_history_rounded, color: Colors.grey, size: 16),
                      const SizedBox(width: 5),
                      Text('${doctor.experienceYears} năm kinh nghiệm', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tóm tắt đánh giá từ Database
                  if (doctor.ratingSummary != null && doctor.ratingSummary!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.thumb_up_alt_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            doctor.ratingSummary!,
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}