import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../Config/BASE_URL.dart'; 

class AdminSpecialtyScreen extends StatefulWidget {
  const AdminSpecialtyScreen({super.key});

  @override
  State<AdminSpecialtyScreen> createState() => _AdminSpecialtyScreenState();
}

class _AdminSpecialtyScreenState extends State<AdminSpecialtyScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchSpecialties();
    });
  }

  // ========================================================
  // POPUP FORM THÊM & CẬP NHẬT CHUYÊN KHOA
  // ========================================================
  void _showSpecialtyForm({Map<String, dynamic>? specialty}) {
    final bool isEdit = specialty != null;
    final nameCtrl = TextEditingController(text: isEdit ? specialty['Ten_chuyen_khoa'] : '');
    final descCtrl = TextEditingController(text: isEdit ? specialty['Mo_ta'] : '');
    Uint8List? selectedImageBytes;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, 
                left: 20, right: 20, top: 20
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 15),
                    Text(isEdit ? "Cập nhật Chuyên Khoa" : "Thêm Chuyên Khoa Mới", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const SizedBox(height: 20),

                    // Chọn ảnh
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setModalState(() => selectedImageBytes = bytes);
                        }
                      },
                      child: Container(
                        height: 80, width: 80,
                        decoration: BoxDecoration(
                          color: kLightCyanBg1,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(selectedImageBytes!, fit: BoxFit.cover))
                            : (isEdit && specialty['Icon'] != null)
                                ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("$BASE_URL${specialty['Icon']}", fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, color: Colors.grey)))
                                : const Icon(Icons.add_photo_alternate, color: kPrimaryColor, size: 30),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tên chuyên khoa
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên chuyên khoa *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: kLightCyanBg1,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Mô tả
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả ngắn',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: kLightCyanBg1,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Lưu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên chuyên khoa!')));
                            return;
                          }
                          Navigator.pop(ctx);
                          
                          Map<String, dynamic> result;
                          if (isEdit) {
                            result = await context.read<AdminViewModel>().updateSpecialty(specialty['Ma_chuyen_khoa'], nameCtrl.text.trim(), descCtrl.text.trim(), selectedImageBytes);
                          } else {
                            result = await context.read<AdminViewModel>().createSpecialty(nameCtrl.text.trim(), descCtrl.text.trim(), selectedImageBytes);
                          }

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red));
                        },
                        child: const Text('LƯU THÔNG TIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Danh mục chuyên khoa',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showSpecialtyForm(),
      ),
      body: adminVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : adminVM.specialties.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu chuyên khoa.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  itemCount: adminVM.specialties.length,
                  itemBuilder: (context, index) {
                    final item = adminVM.specialties[index];
                    final bool isActive = item['Trang_thai'] == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: kBorderCyan)),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: kLightCyanBg1, borderRadius: BorderRadius.circular(10)),
                          child: item['Icon'] != null 
                              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network("$BASE_URL${item['Icon']}", fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.medical_services, color: kPrimaryColor)))
                              : const Icon(Icons.medical_services, color: kPrimaryColor),
                        ),
                        title: Text(item['Ten_chuyen_khoa'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? kTextColor : Colors.grey)),
                        subtitle: Text(
                          item['Mo_ta']?.isNotEmpty == true ? item['Mo_ta'] : "Chưa có mô tả",
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isActive ? kGreyTextColor : Colors.grey, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showSpecialtyForm(specialty: item),
                            ),
                            Switch(
                              value: isActive,
                              activeColor: kPrimaryColor,
                              onChanged: (val) async {
                                final result = await context.read<AdminViewModel>().toggleSpecialtyStatus(item['Ma_chuyen_khoa'], val ? 1 : 0);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red, duration: const Duration(seconds: 1)));
                              },
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