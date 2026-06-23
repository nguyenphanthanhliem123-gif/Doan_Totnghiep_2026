import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/clinic_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/clinic_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart'; // Import để lấy thông tin bác sĩ

class DoctorClinicSelectionScreen extends StatefulWidget {
  const DoctorClinicSelectionScreen({super.key});

  @override
  State<DoctorClinicSelectionScreen> createState() => _DoctorClinicSelectionScreenState();
}

class _DoctorClinicSelectionScreenState extends State<DoctorClinicSelectionScreen> {
  bool _isLoading = false;
  String _searchQuery = '';

  // 💡 THAY ĐỔI QUAN TRỌNG: Chỉ lưu 1 ID duy nhất thay vì một danh sách Set
  int? _currentClinicId; // ID của Nơi khám hiện tại
  int? _primaryClinicId; // ID của Nơi làm việc chính

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Load danh sách tất cả phòng khám
      await context.read<ClinicViewModel>().fetchAllClinic();
      
      // 2. LẤY THÔNG TIN BÁC SĨ ĐỂ TÍCH SẴN
      // (Đảm bảo trước khi vào màn này bạn đã gọi fetchDoctorDetailForDoctor)
      final doctorVM = context.read<DoctorViewModel>();
      final doctor = doctorVM.doctorDetailForDoctor;

      if (mounted && doctor != null) {
        setState(() {
          // 💡 Tại đây, bạn gán ID phòng khám cũ của bác sĩ vào 2 biến này.
          // Ví dụ (Hãy thay bằng đúng tên thuộc tính trong DoctorModel của bạn):
          
          // _currentClinicId = doctor.maPhongKhamHienTai; 
          // _primaryClinicId = doctor.maPhongKhamChinh; 

          // (Demo: Tạm gán giá trị 1 và 3 để bạn hình dung giao diện tích sẵn)
          // _currentClinicId = 1; 
          // _primaryClinicId = 3; 
        });
      }
    });
  }

  // Hàm xử lý lưu dữ liệu
  Future<void> _saveSelection() async {
    if (_currentClinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn 1 cơ sở y tế làm NƠI HIỆN TẠI')));
      return;
    }
    if (_primaryClinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn 1 cơ sở y tế làm NƠI LÀM VIỆC CHÍNH')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 💡 Hướng dẫn cấu trúc JSON gửi lên Backend:
      // Nếu "hiện tại" và "chính" là CÙNG 1 nơi -> Gửi 1 object với noi_chinh: 1
      // Nếu "hiện tại" và "chính" là 2 nơi KHÁC NHAU -> Gửi 2 objects
      List<Map<String, dynamic>> clinicsToSave = [];
      if (_currentClinicId == _primaryClinicId) {
        clinicsToSave.add({"ma_phong_kham": _currentClinicId, "noi_chinh": 1});
      } else {
        clinicsToSave.add({"ma_phong_kham": _currentClinicId, "noi_chinh": 0});
        clinicsToSave.add({"ma_phong_kham": _primaryClinicId, "noi_chinh": 1});
      }

      // 🚀 Gọi API lưu tại đây:
      // await doctorViewModel.updateDoctorClinics(clinicsToSave);
      
      await Future.delayed(const Duration(seconds: 2)); // Giả lập chờ API

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu cơ sở y tế thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context); // Quay về
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicVM = context.watch<ClinicViewModel>();
    
    // Ép kiểu chuẩn để chống lỗi List<Object>
    final List<ClinicModel> allClinics = List<ClinicModel>.from(clinicVM.listClinic ?? []);

    final List<ClinicModel> filteredClinics = _searchQuery.isEmpty 
        ? allClinics 
        : List<ClinicModel>.from(allClinics.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Cơ sở y tế công tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: clinicVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                // ------------------ THANH TÌM KIẾM ------------------
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tên bệnh viện, phòng khám...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ------------------ DANH SÁCH CSYT ------------------
                Expanded(
                  child: filteredClinics.isEmpty 
                      ? const Center(child: Text("Không tìm thấy cơ sở y tế nào", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredClinics.length,
                          itemBuilder: (context, index) {
                            final clinic = filteredClinics[index];
                            final isCurrent = _currentClinicId == clinic.id;
                            final isPrimary = _primaryClinicId == clinic.id;

                            return _buildClinicCard(clinic, isCurrent, isPrimary);
                          },
                        ),
                ),
              ],
            ),

      // ------------------ NÚT LƯU CẬP NHẬT ------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // ------------------ THIẾT KẾ CARD CSYT VỚI 2 NÚT BẤM ĐỘC LẬP ------------------
  Widget _buildClinicCard(ClinicModel clinic, bool isCurrent, bool isPrimary) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Ưu tiên viền cam nếu là Nơi Chính, viền xanh nếu là Hiện tại
          color: isPrimary ? Colors.orangeAccent : (isCurrent ? Colors.blueAccent : Colors.grey.shade200),
          width: (isPrimary || isCurrent) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Phần thông tin (Hình ảnh, Tên, Địa chỉ)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        clinic.images.isNotEmpty 
                          ? clinic.images[0] 
                          : 'https://cdn-icons-png.flaticon.com/512/4320/4320337.png'
                      ), 
                      fit: BoxFit.cover
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clinic.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(clinic.address ?? 'Chưa cập nhật địa chỉ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Phần Action Buttons: CHỈ ĐƯỢC CHỌN 1 HIỆN TẠI VÀ 1 CHÍNH
          Row(
            children: [
              // NÚT CHỌN "NƠI HIỆN TẠI"
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _currentClinicId = clinic.id); // Tự động bỏ chọn cái cũ
                  },
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
                             color: isCurrent ? Colors.blueAccent : Colors.grey, size: 20),
                        const SizedBox(width: 6),
                        Text('Nơi hiện tại', style: TextStyle(color: isCurrent ? Colors.blueAccent : Colors.grey, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),

              Container(width: 1, height: 30, color: Colors.grey.shade200), // Vạch chia giữa

              // NÚT CHỌN "NƠI CHÍNH"
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _primaryClinicId = clinic.id); // Tự động bỏ chọn cái cũ
                  },
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isPrimary ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isPrimary ? Icons.star_rounded : Icons.star_border_rounded, 
                             color: isPrimary ? Colors.orange : Colors.grey, size: 22),
                        const SizedBox(width: 6),
                        Text('Nơi chính', style: TextStyle(color: isPrimary ? Colors.orange : Colors.grey, fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}