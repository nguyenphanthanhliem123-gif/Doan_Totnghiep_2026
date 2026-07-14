import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../models/clinic_model.dart';
import '../../viewmodels/admin_clinic_viewmodel.dart';
import 'package:image_picker/image_picker.dart';

class AdminClinicListScreen extends StatefulWidget {
  const AdminClinicListScreen({super.key});

  @override
  State<AdminClinicListScreen> createState() => _AdminClinicListScreenState();
}

class _AdminClinicListScreenState extends State<AdminClinicListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminClinicViewModel>().fetchClinics();
    });
  }

  Future<void> _pickAndUploadImage(int clinicId) async {
    final picker = ImagePicker();
    // pickedFile trả về đối tượng XFile (chạy được trên cả Web/iOS/Android)
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (!mounted) return;
      
      // Truyền thẳng pickedFile thay vì ép kiểu sang File của dart:io
      final success = await context.read<AdminClinicViewModel>().uploadClinicImage(clinicId, pickedFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Tải ảnh lên thành công!" : "Tải ảnh thất bại!"),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showClinicFormDialog({ClinicModel? clinic}) {
    final isEdit = clinic != null;
    
    // Chỉ giữ lại duy nhất controller của Tên phòng khám
    final nameController = TextEditingController(text: clinic?.name);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Đẩy UI lên khi có bàn phím
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Sửa Tên Phòng Khám' : 'Thêm Phòng Khám Mới', 
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const SizedBox(height: 15),
                
                // Ô nhập tên phòng khám (Duy nhất)
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên phòng khám (*)', 
                    border: OutlineInputBorder()
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập tên phòng khám' : null,
                ),
                
                // Ghi chú cho Admin biết các thông tin khác đã được cài đặt tự động
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    '* Vị trí, Số điện thoại và Email đã được cài đặt mặc định theo thông tin của Bệnh Viện.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        // Cấu hình dữ liệu gửi đi (chỉ cần Tên, các trường kia backend tự xử lý)
                        final data = {
                          "Ten_phong_kham": nameController.text.trim(),
                        };
                        
                        Navigator.pop(context); // Đóng form
                        
                        final success = await context.read<AdminClinicViewModel>().saveClinic(
                          id: clinic?.id, 
                          data: data,
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "Lưu thành công!" : "Lưu thất bại!"), 
                              backgroundColor: success ? Colors.green : Colors.red
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminClinicViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý phòng khám',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () => _showClinicFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.clinics.isEmpty
              ? const Center(child: Text("Chưa có phòng khám nào"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: vm.clinics.length,
                  itemBuilder: (context, index) {
                    final clinic = vm.clinics[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          child: const Icon(Icons.local_hospital, color: kPrimaryColor),
                        ),
                        title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📍 ${clinic.address}", maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (clinic.phone != null && clinic.phone!.isNotEmpty) 
                                Text("📞 ${clinic.phone}"),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate, color: Colors.green),
                              tooltip: 'Thêm ảnh',
                              onPressed: () => _pickAndUploadImage(clinic.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Sửa thông tin',
                              onPressed: () => _showClinicFormDialog(clinic: clinic),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}