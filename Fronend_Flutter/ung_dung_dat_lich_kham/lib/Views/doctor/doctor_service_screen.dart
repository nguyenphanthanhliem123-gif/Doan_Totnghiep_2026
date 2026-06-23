import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/specialtyModel.dart';
import 'package:ung_dung_dat_lich_kham/viewModels/doctor_service_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/models/doctor_detail_model.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/specialty_viewmodel.dart';

// --- GIAO DIỆN CHÍNH ---
class DoctorServicesScreen extends StatefulWidget {
  const DoctorServicesScreen({super.key});

  @override
  State<DoctorServicesScreen> createState() => _DoctorServicesScreenState();
}

class _DoctorServicesScreenState extends State<DoctorServicesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDoctorDetail();
    });
  }

  Future<void> loadDoctorDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      int? doctorId = await context.read<AuthViewModel>().getSavedDoctorId();

      print('==== doctorId: $doctorId');

      if (doctorId != null) {
        if (!mounted) return;
        // Tải chi tiết bác sĩ (bao gồm danh sách dịch vụ)
        await context.read<DoctorViewModel>().fetchDoctorDetail(doctorId);
        if (!mounted) return;
        // Tải danh sách chuyên khoa để phục vụ Dropdown chọn lựa
        await context.read<SpecialtyViewModel>().loadAllSpecialties();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Hàm định dạng tiền tệ VND
  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  // --- HÀM HIỂN THỊ POPUP THÊM / SỬA DỊCH VỤ (MODAL BOTTOM SHEET) ---
  void _openServiceForm({DoctorServiceModel? existingService, List<SpecialtyModel>? spec}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingService?.name ?? '');
    final priceController = TextEditingController(text: existingService?.price.toStringAsFixed(0) ?? '');
    int? selectedSpecId = existingService?.specId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Đẩy giao diện lên khi bàn phím xuất hiện
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return spec == null || spec.isEmpty
            ? const SizedBox(
                height: 150,
                child: Center(child: Text("Không tìm thấy dữ liệu chuyên khoa")),
              )
            : Padding(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Tránh đè bàn phím
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              existingService == null ? 'Thêm dịch vụ mới' : 'Chỉnh sửa dịch vụ',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.grey),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tên dịch vụ
                        const Text('Tên dịch vụ chuyên sâu', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'VD: Siêu âm tim mạch bọc màu, nội soi...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên dịch vụ' : null,
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Chọn Chuyên khoa
                        const Text('Thuộc chuyên khoa', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedSpecId,
                          items: spec.map((cat) {
                            return DropdownMenuItem<int>(value: cat.id, child: Text(cat.name));
                          }).toList(),
                          onChanged: (val) => selectedSpecId = val,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => val == null ? 'Vui lòng chọn chuyên khoa' : null,
                        ),
                        const SizedBox(height: 16),

                        // Giá dịch vụ
                        const Text('Giá dịch vụ (VND)', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Chỉ cho nhập số
                          decoration: InputDecoration(
                            hintText: 'VD: 200000',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            suffixText: 'đ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giá tiền';
                            if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Giá tiền không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Nút hành động (Xác nhận gửi dữ liệu lên Server)
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final price = double.parse(priceController.text);

                              // Đóng bottom sheet trước khi chạy tác vụ bất đồng bộ
                              Navigator.pop(context);
                              
                              setState(() => _isLoading = true);
                              bool isSuccess = false;
                              // 💡 ĐÃ KÍCH HOẠT THÀNH CÔNG: Gọi API thông qua ViewModel để cập nhật Database công khai
                              try {
                                if (existingService == null) {
                                  // KÍCH HOẠT LOGIC TẠO MỚI DỊCH VỤ
                                  isSuccess = await context.read<DoctorServiceViewModel>().addService(
                                    nameController.text.trim(), 
                                    selectedSpecId!, 
                                    price
                                  );
                                } else {
                                  // KÍCH HOẠT LOGIC CHỈNH SỬA DỊCH VỤ
                                  isSuccess = await context.read<DoctorServiceViewModel>().editService(
                                    existingService.id,
                                    name: nameController.text.trim(),
                                    specId: selectedSpecId!,
                                    price: price,
                                  );
                                }

                                // 💡 Dựa vào kết quả thật để hiển thị thông báo phù hợp
                                if (isSuccess) {
                                  await loadDoctorDetail(); // Reload lại giao diện

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(existingService == null ? 'Thêm thành công!' : 'Đã cập nhật dịch vụ'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  // Nếu trả về false, tức là có lỗi từ Backend hoặc dữ liệu không đổi
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Không thể lưu thay đổi. Vui lòng kiểm tra lại dữ liệu hoặc ID dịch vụ!'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Không thể lưu thay đổi: $e'), backgroundColor: Colors.red),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            existingService == null ? 'Thêm mới dịch vụ' : 'Lưu thay đổi',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
      },
    );
  }

  // --- HÀM XÓA DỊCH VỤ ---
  void _deleteService(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa dịch vụ?'),
        content: const Text('Bệnh nhân sẽ không thể chọn ca khám ứng với dịch vụ này nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng hộp thoại alert trước
              setState(() => _isLoading = true);

              try {
                // 💡 ĐÃ KÍCH HOẠT THÀNH CÔNG: Gọi hàm xóa của DoctorViewModel lên API Server Realtime
                await context.read<DoctorServiceViewModel>().removeService(id);
                
                // Tải lại danh sách mới nhất từ Database sau khi xóa thành công
                await loadDoctorDetail();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa dịch vụ thành công'), backgroundColor: Colors.redAccent),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi xóa dịch vụ: $e'), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();
    final specialtyVM = context.watch<SpecialtyViewModel>();

    final doctor = doctorVM.doctorDetail;
    final List<SpecialtyModel>? specList = specialtyVM.listSpecialty; 

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dịch vụ & Giá khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: doctorVM.isLoading || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : doctor == null || doctor.services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Chưa có dịch vụ nào', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctor.services.length,
                  itemBuilder: (context, index) {
                    final service = doctor.services[index]; 
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    service.specName,
                                    style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  service.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatCurrency(service.price),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                                onPressed: () => _openServiceForm(existingService: service, spec: specList),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteService(service.id),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceForm(spec: specList),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}