import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Models/serviceModel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/auth_viewmodel.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_viewmodel.dart';
import '../../Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/doctor_service_viewmodel.dart';

class DoctorServiceManagementScreen extends StatefulWidget {

  const DoctorServiceManagementScreen({super.key});

  @override
  State<DoctorServiceManagementScreen> createState() => _DoctorServiceManagementScreenState();
}

class _DoctorServiceManagementScreenState extends State<DoctorServiceManagementScreen> {
  bool isLoading = false;
  int? _doctorId;

  @override
  void initState() {
    fetchDoctorId();
    super.initState();
  }

  Future<void> fetchDoctorId() async {
    setState(() {
      isLoading = true;
    });
    final doctorId = await context.read<AuthViewModel>().getSavedDoctorId();

    if(doctorId == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy mã bác sĩ'))
      );
    }else{
      _doctorId = doctorId;
      context.read<DoctorServiceViewModel>().fetchMyServices(doctorId);
      context.read<DoctorViewModel>().fetchDoctorDetail(doctorId);
    }

    setState(() {
      isLoading = false;
    });
  }

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  // Mở Dialog chọn dịch vụ mẫu của chuyên khoa
  void _showAddServiceDialog() {
    final docVM = context.read<DoctorViewModel>();
    final doctor = docVM.doctorDetail;

    // 1. Kiểm tra an toàn: Nếu chưa tải xong thông tin bác sĩ thì báo lỗi chứ không để Crash app
    if (doctor == null || doctor.specialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải thông tin chuyên khoa, vui lòng thử lại sau giây lát!'))
      );
      return;
    }

    final viewModel = context.read<DoctorServiceViewModel>();
    
    // 2. Gọi API lấy danh sách dịch vụ gốc
    viewModel.fetchAvailableMaster(doctor.specialtyId!, _doctorId ?? 0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer<DoctorServiceViewModel>(
          builder: (context, vm, child) {
            
            // 3. Hiển thị vòng xoay Loading trong lúc đợi API trả dữ liệu về
            if (vm.isLoading) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
              );
            }

            if (vm.availableMasterServices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(30.0),
                child: Text('Không có dịch vụ mẫu nào mới để chọn.', textAlign: TextAlign.center),
              );
            }
            
            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn dịch vụ đăng ký khám', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: vm.availableMasterServices.length,
                      itemBuilder: (context, index) {
                        final item = vm.availableMasterServices[index];
                        return ListTile(
                          title: Text(item.serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Giá gốc: ${formatCurrency(item.price)}'),
                          trailing: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
                          onTap: () {
                            Navigator.pop(context);
                            // Pass the correct properties
                            _showPriceConfigDialog(item.id, item.serviceName, item.price);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Dialog nhập giá tùy chỉnh của Bác sĩ
  void _showPriceConfigDialog(int masterId, String serviceName, double defaultPrice) {
    final priceController = TextEditingController(text: defaultPrice.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
        title: Text(serviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập mức giá bạn muốn áp dụng cho dịch vụ này:', style: TextStyle(fontSize: 13, color: kTextColor)),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá tiền dịch vụ (vnđ)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixText: 'đ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, elevation: 0),
            onPressed: () async {
              double? inputPrice = double.tryParse(priceController.text);
              if (inputPrice == null || inputPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập giá hợp lệ')));
                return;
              }
              Navigator.pop(context);
              
              bool success = await context.read<DoctorServiceViewModel>().chooseService(_doctorId!, masterId, inputPrice);
              if (success) {
                context.read<DoctorServiceViewModel>().fetchMyServices(_doctorId!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm dịch vụ thành công!')));
              }
            },
            child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('Quản lý dịch vụ', style: kHeaderTextStyle), // 🌟 Text Style chuẩn
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: _showAddServiceDialog,
          )
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Consumer<DoctorServiceViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          if (vm.myServices.isEmpty) {
            return const Center(child: Text('Bạn chưa chọn dịch vụ nào. Hãy ấn dấu (+) để thêm.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.myServices.length,
            itemBuilder: (context, index) {
              final MyServiceModel service = vm.myServices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(service.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                  subtitle: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      formatCurrency(service.price),
                      style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      bool success = await vm.removeService(service.id, _doctorId!);
                      if (success) {
                        vm.fetchMyServices(_doctorId!);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa dịch vụ khỏi hồ sơ khám.')));
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}