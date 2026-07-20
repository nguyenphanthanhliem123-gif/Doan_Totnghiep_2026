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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (!mounted) return;
      
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

  void _showClinicFormDialog({required ClinicModel clinic}) {
    final nameController = TextEditingController(text: clinic.name);
    final addressController = TextEditingController(text: clinic.address);
    final phoneController = TextEditingController(text: clinic.phone);
    final emailController = TextEditingController(text: clinic.email ?? ''); 
    final websiteController = TextEditingController(text: clinic.website ?? '');
    final utilitiesController = TextEditingController(text: clinic.util ?? '');
    final descController = TextEditingController(text: clinic.description ?? '');

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cập Nhật Thông Tin Phòng Khám', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)
                  ),
                  const SizedBox(height: 15),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên phòng khám (*)', border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập tên phòng khám' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ / Vị trí (*)', border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập địa chỉ phòng khám' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email phòng khám', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: websiteController,
                    decoration: const InputDecoration(labelText: 'Link trang web (URL)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: utilitiesController,
                    decoration: const InputDecoration(labelText: 'Tiện ích (Wifi, Máy lạnh...)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mô tả chi tiết phòng khám', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final data = {
                            "Ten_phong_kham": nameController.text.trim(),
                            "Vi_tri": addressController.text.trim(),
                            "Dien_thoai": phoneController.text.trim(),
                            "Email": emailController.text.trim(),
                            "Link_trang_web": websiteController.text.trim(),
                            "Tien_ich": utilitiesController.text.trim(),
                            "Mo_ta_phong_kham": descController.text.trim(),
                          };
                          
                          Navigator.pop(context);
                          
                          final success = await context.read<AdminClinicViewModel>().saveClinic(
                            id: clinic.id, 
                            data: data,
                          );
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? "Cập nhật thành công!" : "Cập nhật thất bại!"), 
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
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.clinics.isEmpty
              ? const Center(child: Text("Chưa có thông tin phòng khám"))
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
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📍 ${clinic.address}", maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (clinic.phone != null && clinic.phone!.isNotEmpty) 
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0), // 🛠️ ĐÃ SỬA LỖI TẠI ĐÂY
                                  child: Text("📞 ${clinic.phone}"),
                                ),
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
                              tooltip: 'Chỉnh sửa',
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