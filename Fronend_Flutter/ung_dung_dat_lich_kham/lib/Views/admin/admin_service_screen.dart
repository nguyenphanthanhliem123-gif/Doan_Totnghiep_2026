import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_service_viewmodel.dart';

class AdminServiceScreen extends StatefulWidget {
  const AdminServiceScreen({super.key});

  @override
  State<AdminServiceScreen> createState() => _AdminServiceScreenState();
}

class _AdminServiceScreenState extends State<AdminServiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminServiceViewModel>().fetchSpecialties();
      context.read<AdminServiceViewModel>().fetchServices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm xử lý delay khi tìm kiếm (tránh gọi API liên tục khi đang gõ)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AdminServiceViewModel>().fetchServices(
        search: query, 
        specId: _selectedSpecId ?? ''
      );
    });
  }

  String formatCurrency(double amount) {
    String result = amount.toStringAsFixed(0);
    result = result.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$result vnđ';
  }

  // Hộp thoại chung để THÊM hoặc SỬA dịch vụ
  void _showAddOrEditDialog({Map<String, dynamic>? item}) {
    final bool isEdit = item != null;
    
    final nameController = TextEditingController(text: isEdit ? item['Ten_dich_vu'] : '');
    final priceController = TextEditingController(text: isEdit ? item['Gia_mac_dinh'].toString() : '');
    
    // Nếu sửa, gán lại giá trị specId cũ
    int? selectedDialogSpecId = isEdit ? item['Ma_chuyen_khoa'] : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Sửa dịch vụ gốc' : 'Thêm dịch vụ gốc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nhập tên
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
                    ),
                    const SizedBox(height: 15),
                    
                    // Chọn chuyên khoa
                    Consumer<AdminServiceViewModel>(
                      builder: (context, vm, child) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Chuyên khoa'),
                          value: selectedDialogSpecId,
                          isExpanded: true,
                          items: vm.specialties.map<DropdownMenuItem<int>>((spec) {
                            return DropdownMenuItem<int>(
                              value: spec['Ma_chuyen_khoa'] ?? spec['id'], // Chỉnh lại theo key API của bạn
                              child: Text(spec['Ten_chuyen_khoa'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateDialog(() => selectedDialogSpecId = val);
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 15),
                    
                    // Nhập giá
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá mặc định (VNĐ)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Hủy')
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || selectedDialogSpecId == null || priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin')));
                      return;
                    }

                    double price = double.tryParse(priceController.text) ?? 0.0;
                    bool success = false;

                    if (isEdit) {
                      success = await context.read<AdminServiceViewModel>().updateService(
                        item['id'], nameController.text, selectedDialogSpecId!, price
                      );
                    } else {
                      success = await context.read<AdminServiceViewModel>().addService(
                        nameController.text, selectedDialogSpecId!, price
                      );
                    }

                    if (success) {
                      Navigator.pop(context);
                      context.read<AdminServiceViewModel>().fetchServices(
                        search: _searchController.text, specId: _selectedSpecId ?? ''
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Đã sửa thành công' : 'Đã thêm thành công')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                  child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm mới', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Hộp thoại xác nhận XÓA
  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa dịch vụ "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Đóng hộp thoại
              Map<String, dynamic> success = await context.read<AdminServiceViewModel>().deleteService(id);
              if (success["succeeded"]) {
                context.read<AdminServiceViewModel>().fetchServices();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa dịch vụ')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success['message'])));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý dịch vụ',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AdminServiceViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // --- Vùng Tìm kiếm và Lọc ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Tìm tên dịch vụ...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        hint: const Text('Tất cả Khoa', style: TextStyle(fontSize: 13)),
                        value: _selectedSpecId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(value: '', child: Text('Tất cả')), // Option Tất cả
                          ...vm.specialties.map((spec) => DropdownMenuItem<String>(
                            value: spec['Ma_chuyen_khoa']?.toString() ?? spec['id'].toString(),
                            child: Text(spec['Ten_chuyen_khoa'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ))
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedSpecId = val;
                          });
                          vm.fetchServices(search: _searchController.text, specId: val ?? '');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // --- Vùng Hiển thị Danh sách ---
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : vm.services.isEmpty
                        ? const Center(child: Text('Không tìm thấy dịch vụ nào.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: vm.services.length,
                            itemBuilder: (context, index) {
                              final item = vm.services[index];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Text(item['Ten_dich_vu'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Khoa: ${item['Ten_chuyen_khoa'] ?? 'Không rõ'}', style: TextStyle(color: Colors.grey.shade700)),
                                        Text(
                                          'Giá gốc: ${formatCurrency(double.tryParse(item['Gia_mac_dinh'].toString()) ?? 0)}',
                                          style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showAddOrEditDialog(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _confirmDelete(item['id'], item['Ten_dich_vu']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}